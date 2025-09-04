public with sharing class JeffKPIController {

    public class KPIUser implements Comparable {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String partner;
        @AuraEnabled public Decimal pipeline;
        @AuraEnabled public Integer openCount;
        @AuraEnabled public Integer overdueCount;
        @AuraEnabled public Integer proposedCount;
        @AuraEnabled public Decimal wonAmount;
        @AuraEnabled public Integer wonCount;
        @AuraEnabled public Decimal winRate;

        public Integer compareTo(Object o) {
            KPIUser other = (KPIUser)o;
            Decimal a = (this.wonAmount == null) ? 0 : this.wonAmount;
            Decimal b = (other.wonAmount == null) ? 0 : other.wonAmount;
            if (a == b) return 0;
            return (a > b) ? -1 : 1;
        }
    }

    public class Option {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    public class FilterOptions {
        @AuraEnabled public List<Option> timeframeOptions;
        @AuraEnabled public List<Option> ownerOptions;
        @AuraEnabled public List<Option> partnerOptions;
    }

    private static Option opt(String l, String v) {
        Option o = new Option(); o.label=l; o.value=v; return o;
    }

    @AuraEnabled(cacheable=true)
    public static FilterOptions getFilterOptions() {
        FilterOptions f = new FilterOptions();
        f.timeframeOptions = new List<Option>{
            opt('All Time','ALL'),
            opt('This Month','MTD'),
            opt('This Quarter','QTD'),
            opt('This Year','YTD')
        };

        f.ownerOptions = new List<Option>();
        for (User u : [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name LIMIT 200]) {
            f.ownerOptions.add(opt(u.Name, (String)u.Id));
        }

        f.partnerOptions = new List<Option>();
        for (AggregateResult ar : [SELECT Partner__c p FROM User WHERE Partner__c != null GROUP BY Partner__c]) {
            f.partnerOptions.add(opt((String)ar.get('p'), (String)ar.get('p')));
        }

        return f;
    }

    private static Date calcStart(String timeframe) {
        if (timeframe == null) return null;
        Date today = Date.today();
        if (timeframe == 'MTD') {
            return Date.newInstance(today.year(), today.month(), 1);
        }
        if (timeframe == 'QTD') {
            Integer q = ((today.month() - 1) / 3) + 1;
            Integer sm = ((q - 1) * 3) + 1;
            return Date.newInstance(today.year(), sm, 1);
        }
        if (timeframe == 'YTD') {
            return Date.newInstance(today.year(), 1, 1);
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<KPIUser> getKPIs(String timeframe, Id ownerId, String partner, Integer topN) {
        if (topN == null || topN <= 0) topN = 25;
        Date startDate = calcStart(timeframe);
        Date endDate = Date.today();

        String baseWhere = 'IsClosed = false';
        if (ownerId != null) baseWhere += ' AND OwnerId = :ownerId';
        if (partner != null) baseWhere += ' AND Owner.Partner__c = :partner';

        List<AggregateResult> openAgg = Database.query(
            'SELECT OwnerId oid, SUM(Amount) total, COUNT(Id) cnt ' +
            'FROM Opportunity WHERE ' + baseWhere + ' GROUP BY OwnerId'
        );

        String wonWhere = 'IsWon = true';
        if (ownerId != null) wonWhere += ' AND OwnerId = :ownerId';
        if (partner != null) wonWhere += ' AND Owner.Partner__c = :partner';
        if (startDate != null) wonWhere += ' AND CloseDate >= :startDate AND CloseDate <= :endDate';

        List<AggregateResult> wonAgg = Database.query(
            'SELECT OwnerId oid, SUM(Amount) total, COUNT(Id) cnt ' +
            'FROM Opportunity WHERE ' + wonWhere + ' GROUP BY OwnerId'
        );

        Set<Id> ownerIds = new Set<Id>();
        for (AggregateResult a : openAgg) ownerIds.add((Id)a.get('oid'));
        for (AggregateResult a : wonAgg) ownerIds.add((Id)a.get('oid'));

        Map<Id, User> users = new Map<Id, User>();
        if (!ownerIds.isEmpty()) {
            users = new Map<Id, User>([SELECT Id, Name, Partner__c FROM User WHERE Id IN :ownerIds]);
        }

        Map<Id,KPIUser> mapK = new Map<Id,KPIUser>();
        for (Id oid : ownerIds) {
            KPIUser k = new KPIUser();
            k.userId = oid;
            k.userName = users.containsKey(oid) ? users.get(oid).Name : String.valueOf(oid);
            k.partner = users.containsKey(oid) ? users.get(oid).Partner__c : null;
            mapK.put(oid, k);
        }

        for (AggregateResult a : openAgg) {
            Id oid = (Id)a.get('oid');
            KPIUser k = mapK.get(oid);
            k.pipeline = (Decimal)a.get('total');
            k.openCount = (Integer)a.get('cnt');
        }
        for (AggregateResult a : wonAgg) {
            Id oid = (Id)a.get('oid');
            KPIUser k = mapK.get(oid);
            k.wonAmount = (Decimal)a.get('total');
            k.wonCount = (Integer)a.get('cnt');
        }

        for (KPIUser k : mapK.values()) {
            Integer attempts = (k.openCount + k.wonCount);
            if (attempts > 0) {
                k.winRate = (Decimal.valueOf(k.wonCount) / Decimal.valueOf(attempts)) * 100;
            }
        }

        List<KPIUser> out = new List<KPIUser>();
        out.addAll(mapK.values());
        out.sort();
        Integer limitN = Math.min(topN, out.size());
        List<KPIUser> result = new List<KPIUser>();
        for (Integer i = 0; i < limitN; i++) {
            result.add(out[i]);
        }
        return result;
    }
}