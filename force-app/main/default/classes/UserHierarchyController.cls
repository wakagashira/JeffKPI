public with sharing class UserHierarchyController {

    public class UserActivitySummary {
        @AuraEnabled public Id userId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer callCount;
        @AuraEnabled public Integer meetingCount;
        @AuraEnabled public Integer emailCount;
        @AuraEnabled public String partnerName;
    }

    public class OpportunityMetrics {
        @AuraEnabled public Decimal pipelineValue;
        @AuraEnabled public Decimal averageDealSize;
        @AuraEnabled public Decimal conversionRate; // percent
        @AuraEnabled public Integer closedWonCount;
        @AuraEnabled public Integer createdCount;
    }

    private static Map<String, String> timeframeLiterals() {
        return new Map<String, String>{
            'Today' => 'TODAY',
            'Yesterday' => 'YESTERDAY',
            'ThisWeek' => 'THIS_WEEK',
            'LastWeek' => 'LAST_WEEK',
            'Last7Days' => 'LAST_N_DAYS:7',
            'ThisMonth' => 'THIS_MONTH',
            'LastMonth' => 'LAST_MONTH',
            'ThisQuarter' => 'THIS_QUARTER',
            'LastQuarter' => 'LAST_QUARTER',
            'ThisYear' => 'THIS_YEAR',
            'LastYear' => 'LAST_YEAR'
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<UserActivitySummary> getUserActivitySummary(String timeframe) {
        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId == null) return new List<UserActivitySummary>();

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        Map<Id, User> usersById = new Map<Id, User>(
            [SELECT Id, Name, Partner__c
             FROM User
             WHERE UserRoleId IN :roleIds AND IsActive = true]
        );
        if (usersById.isEmpty()) return new List<UserActivitySummary>();

        String literal = timeframeLiterals().get(timeframe);
        if (String.isBlank(literal)) literal = 'LAST_N_DAYS:30';

        Set<Id> userIds = usersById.keySet();

        // Calls
        Map<Id, Integer> callCounts = new Map<Id, Integer>();
        for (AggregateResult ar : Database.query(
            'SELECT OwnerId ownerId, COUNT(Id) cnt FROM Task ' +
            'WHERE OwnerId IN :userIds AND Type = \'Call\' AND ActivityDate = ' + literal + ' ' +
            'GROUP BY OwnerId')) {
            callCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        // Emails
        Map<Id, Integer> emailCounts = new Map<Id, Integer>();
        for (AggregateResult ar : Database.query(
            'SELECT OwnerId ownerId, COUNT(Id) cnt FROM Task ' +
            'WHERE OwnerId IN :userIds AND Type = \'Email\' AND ActivityDate = ' + literal + ' ' +
            'GROUP BY OwnerId')) {
            emailCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        // Meetings
        Map<Id, Integer> meetingCounts = new Map<Id, Integer>();
        for (AggregateResult ar : Database.query(
            'SELECT OwnerId ownerId, COUNT(Id) cnt FROM Event ' +
            'WHERE OwnerId IN :userIds AND StartDateTime = ' + literal + ' ' +
            'GROUP BY OwnerId')) {
            meetingCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        List<UserActivitySummary> results = new List<UserActivitySummary>();
        for (User u : usersById.values()) {
            UserActivitySummary uas = new UserActivitySummary();
            uas.userId = u.Id;
            uas.name = u.Name;
            uas.partnerName = u.Partner__c;
            uas.callCount = callCounts.containsKey(u.Id) ? callCounts.get(u.Id) : 0;
            uas.emailCount = emailCounts.containsKey(u.Id) ? emailCounts.get(u.Id) : 0;
            uas.meetingCount = meetingCounts.containsKey(u.Id) ? meetingCounts.get(u.Id) : 0;
            results.add(uas);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityMetrics getOpportunityMetrics(String timeframe) {
        OpportunityMetrics m = new OpportunityMetrics();
        m.pipelineValue = 0; m.averageDealSize = 0; m.conversionRate = 0;
        m.closedWonCount = 0; m.createdCount = 0;

        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId == null) return m;

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        Set<Id> userIds = new Set<Id>(
            new Map<Id, User>([SELECT Id FROM User WHERE UserRoleId IN :roleIds AND IsActive = true]).keySet()
        );
        if (userIds.isEmpty()) return m;

        String literal = timeframeLiterals().get(timeframe);
        if (String.isBlank(literal)) literal = 'LAST_N_DAYS:30';

        // Pipeline (open opps)
        AggregateResult[] pipelineAr = Database.query(
            'SELECT SUM(Amount) sumAmt FROM Opportunity ' +
            'WHERE OwnerId IN :userIds AND IsClosed = false AND CloseDate = ' + literal
        );
        if (!pipelineAr.isEmpty() && pipelineAr[0].get('sumAmt') != null)
            m.pipelineValue = (Decimal)pipelineAr[0].get('sumAmt');

        // Closed Won in timeframe
        AggregateResult[] wonAr = Database.query(
            'SELECT COUNT(Id) cnt, SUM(Amount) sumAmt FROM Opportunity ' +
            'WHERE OwnerId IN :userIds AND IsWon = true AND CloseDate = ' + literal
        );
        Integer wonCount = 0;
        Decimal wonSum = 0;
        if (!wonAr.isEmpty()) {
            Object cnt = wonAr[0].get('cnt');
            Object s = wonAr[0].get('sumAmt');
            wonCount = (cnt == null) ? 0 : (Integer)cnt;
            wonSum = (s == null) ? 0 : (Decimal)s;
        }
        m.closedWonCount = wonCount;
        if (wonCount > 0) m.averageDealSize = wonSum / wonCount;

        // Opportunities created in timeframe
        AggregateResult[] createdAr = Database.query(
            'SELECT COUNT(Id) cnt FROM Opportunity ' +
            'WHERE OwnerId IN :userIds AND CreatedDate = ' + literal
        );
        Integer createdCnt = 0;
        if (!createdAr.isEmpty() && createdAr[0].get('cnt') != null)
            createdCnt = (Integer)createdAr[0].get('cnt');
        m.createdCount = createdCnt;

        // Conversion Rate
        if (createdCnt > 0) m.conversionRate = (Decimal)wonCount * 100 / createdCnt;

        return m;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersInMyHierarchy() {
        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId == null) return new List<User>();

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        return [
            SELECT Id, Name, FirstName, LastName, Email, Title, UserRole.Name, Partner__c
            FROM User
            WHERE UserRoleId IN :roleIds AND IsActive = true
            ORDER BY Name
        ];
    }

    private static void collectChildRoles(Id parentRoleId, Set<Id> roleIds) {
        for (UserRole ur : [SELECT Id FROM UserRole WHERE ParentRoleId = :parentRoleId]) {
            if (!roleIds.contains(ur.Id)) {
                roleIds.add(ur.Id);
                collectChildRoles(ur.Id, roleIds);
            }
        }
    }
}