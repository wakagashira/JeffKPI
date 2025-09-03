public with sharing class JeffKPIController {
    public class Option {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public Option(String v, String l) { value = v; label = l; }
    }
    public class KPIResponse {
        @AuraEnabled public Decimal totalPipelineAmount;
        @AuraEnabled public Integer openOppCount;
        @AuraEnabled public Integer proposedCount;
        @AuraEnabled public Integer overdueOpps;
        @AuraEnabled public Integer activities;
        @AuraEnabled public Decimal winRate;
    }
    public class FilterOptions {
        @AuraEnabled public List<Option> partners;
        @AuraEnabled public List<Option> users;
    }
    public class UserKPI {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Decimal totalPipelineAmount;
        @AuraEnabled public Integer openOppCount;
        @AuraEnabled public Integer proposedCount;
        @AuraEnabled public Integer overdueOpps;
        @AuraEnabled public Integer activities;
        @AuraEnabled public Decimal winRate;
        @AuraEnabled public Integer callCount;
        @AuraEnabled public Integer emailCount;
        @AuraEnabled public Integer taskCount;
        @AuraEnabled public Integer meetingCount;
    }

    @AuraEnabled(cacheable=true)
    public static FilterOptions getFilterOptions() {
        FilterOptions fo = new FilterOptions();
        fo.partners = new List<Option>();
        fo.users = new List<Option>();

        // Partner options from User.Partner__c (distinct, active users only)
        Set<String> partnerNames = new Set<String>();
        for (User u : [SELECT Partner__c FROM User WHERE Partner__c != null AND IsActive = true]) {
            partnerNames.add(u.Partner__c);
        }
        for (String pname : partnerNames) {
            fo.partners.add(new Option(pname, pname));
        }

        // User options (active users)
        for (User u : [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name LIMIT 2000]) {
            fo.users.add(new Option(u.Id, u.Name));
        }
        return fo;
    }

    @AuraEnabled(cacheable=true)
    public static List<UserKPI> getUserKpis(String partnerName, Integer timeframeDays) {
        if (timeframeDays == null) timeframeDays = 7;
        Date cutoffDate = System.today().addDays(-timeframeDays);

        // Users belonging to the partner (if provided)
        Set<Id> partnerUsers = new Set<Id>();
        if (partnerName != null) {
            for (User u : [SELECT Id FROM User WHERE Partner__c = :partnerName AND IsActive = true]) {
                partnerUsers.add(u.Id);
            }
        }

        String baseWhere = ' WHERE IsClosed = false';
        if (!partnerUsers.isEmpty()) baseWhere += ' AND OwnerId IN :partnerUsers';

        List<Opportunity> openOpps = Database.query('SELECT Id, OwnerId, Amount, StageName, CloseDate FROM Opportunity' + baseWhere + ' LIMIT 5000');
        Map<Id, UserKPI> byOwner = new Map<Id, UserKPI>();
        Map<Id, Id> oppToOwner = new Map<Id, Id>();
        for (Opportunity o : openOpps) {
            oppToOwner.put(o.Id, o.OwnerId);
            if (!byOwner.containsKey(o.OwnerId)) {
                UserKPI k = new UserKPI();
                k.userId = o.OwnerId; k.userName = null;
                k.totalPipelineAmount=0; k.openOppCount=0; k.proposedCount=0; k.overdueOpps=0; k.activities=0;
                k.callCount=0; k.emailCount=0; k.taskCount=0; k.meetingCount=0; k.winRate=0;
                byOwner.put(o.OwnerId, k);
            }
            UserKPI ku = byOwner.get(o.OwnerId);
            ku.openOppCount++;
            if (o.Amount != null) ku.totalPipelineAmount += o.Amount;
            if (o.StageName == 'Proposed' || o.StageName == 'Proposal / Audit Generation') ku.proposedCount++;
            if (o.CloseDate != null && o.CloseDate < Date.today()) ku.overdueOpps++;
        }

        // Aggregate tasks by subtype across owners found above
        if (!byOwner.isEmpty()) {
            List<AggregateResult> taskAggs = [
                SELECT OwnerId, TaskSubtype, COUNT(Id) cnt
                FROM Task
                WHERE ActivityDate >= :cutoffDate
                AND OwnerId IN :byOwner.keySet()
                GROUP BY OwnerId, TaskSubtype
            ];
            for (AggregateResult ar : taskAggs) {
                Id ownerId = (Id) ar.get('OwnerId');
                String subtype = (String) ar.get('TaskSubtype');
                Integer c = (Integer) ar.get('cnt');
                if (byOwner.containsKey(ownerId)) {
                    UserKPI k = byOwner.get(ownerId);
                    if (subtype == 'Call') k.callCount += c;
                    else if (subtype == 'Email') k.emailCount += c;
                    else k.taskCount += c;
                    k.activities += c;
                }
            }

            // Meetings (Events)
            List<AggregateResult> eventAggs = [
                SELECT OwnerId, COUNT(Id) cnt
                FROM Event
                WHERE ActivityDate >= :cutoffDate
                AND OwnerId IN :byOwner.keySet()
                GROUP BY OwnerId
            ];
            for (AggregateResult ar : eventAggs) {
                Id ownerId = (Id) ar.get('OwnerId');
                Integer c = (Integer) ar.get('cnt');
                if (byOwner.containsKey(ownerId)) {
                    UserKPI k = byOwner.get(ownerId);
                    k.meetingCount += c;
                    k.activities += c;
                }
            }
        }

        // Win rates by owner
        String winQuery = 'SELECT OwnerId oid, IsWon won, COUNT(Id) cnt FROM Opportunity WHERE IsClosed = true AND CloseDate >= :cutoffDate';
        if (!partnerUsers.isEmpty()) winQuery += ' AND OwnerId IN :partnerUsers';
        winQuery += ' GROUP BY OwnerId, IsWon';
        List<AggregateResult> winAggs = Database.query(winQuery);

        Map<Id,Integer> wins = new Map<Id,Integer>(); Map<Id,Integer> totals = new Map<Id,Integer>();
        for (AggregateResult ag : winAggs) {
            Id oid = (Id) ag.get('oid'); Boolean won = (Boolean) ag.get('won'); Integer c = (Integer) ag.get('cnt');
            totals.put(oid, (totals.containsKey(oid)?totals.get(oid):0)+c);
            if (won) wins.put(oid, (wins.containsKey(oid)?wins.get(oid):0)+c);
            if (!byOwner.containsKey(oid)) { UserKPI k3 = new UserKPI(); k3.userId=oid; byOwner.put(oid,k3); }
        }
        for (Id oid : byOwner.keySet()) {
            Integer t = totals.containsKey(oid)?totals.get(oid):0;
            Integer w = wins.containsKey(oid)?wins.get(oid):0;
            byOwner.get(oid).winRate = t>0 ? ((Decimal)w*100)/(Decimal)t : 0;
        }

        // Fill in user names
        if (!byOwner.isEmpty()) {
            for (User u : [SELECT Id, Name FROM User WHERE Id IN :byOwner.keySet()]) {
                byOwner.get(u.Id).userName = u.Name;
            }
        }
        return new List<UserKPI>(byOwner.values());
    }
}
