
// v4.2 — Adds User & Partner (User.Partner__c) filters while keeping legacy methods intact
public with sharing class JeffKPIController {
    public class Option {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public Option(String l, String v) { label = l; value = v; }
    }
    public class UserActivitySummary {
        @AuraEnabled public Integer openTasks;
        @AuraEnabled public Integer completedTasks;
        @AuraEnabled public Integer events;
    }
    public class OpportunityMetrics {
        @AuraEnabled public Integer openCount;
        @AuraEnabled public Decimal openAmount;
        @AuraEnabled public Integer wonCount;
        @AuraEnabled public Decimal wonAmount;
        @AuraEnabled public Integer lostCount;
        @AuraEnabled public Decimal lostAmount;
    }

    // ===== Options =====
    @AuraEnabled(cacheable=true)
    public static List<Option> getUserOptions() {
        List<Option> opts = new List<Option>();
        for (User u : [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
            ORDER BY Name
            LIMIT 10000
        ]) {
            opts.add(new Option(u.Name, (String)u.Id));
        }
        return opts;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getPartnerOptions() {
        List<Option> opts = new List<Option>();
        for (AggregateResult ar : [
            SELECT Partner__c p
            FROM User
            WHERE IsActive = true AND Partner__c != null
            GROUP BY Partner__c
            ORDER BY Partner__c
        ]) {
            String p = (String) ar.get('p');
            opts.add(new Option(p, p));
        }
        return opts;
    }

    // ===== Legacy compatible methods (no filters) =====
    @AuraEnabled(cacheable=true)
    public static UserActivitySummary getUserActivitySummary(String timeframe) {
        return getUserActivitySummaryFiltered(timeframe, null, null);
    }
    @AuraEnabled(cacheable=true)
    public static OpportunityMetrics getOpportunityMetrics(String timeframe) {
        return getOpportunityMetricsFiltered(timeframe, null, null);
    }

    // ===== Filter-enabled methods =====
    @AuraEnabled(cacheable=true)
    public static UserActivitySummary getUserActivitySummaryFiltered(String timeframe, Id selectedUserId, String selectedPartner) {
        Set<Id> ownerIds = resolveOwnerIds(selectedUserId, selectedPartner);

        DateTimeRange r = computeRange(timeframe);
        UserActivitySummary s = new UserActivitySummary();

        // Open Tasks (status not completed) due in range OR with no due date
        String taskWhere = ' IsDeleted = false ';
        if (ownerIds != null && !ownerIds.isEmpty()) taskWhere += ' AND OwnerId IN :ownerIds ';
        // Use ActivityDate for due date; count tasks with due date in range OR null
        List<AggregateResult> taskOpen = Database.query('SELECT COUNT(Id) c FROM Task WHERE ' + taskWhere +
            ' AND (Status != \'Completed\' AND (ActivityDate = null OR (ActivityDate >= :r.startDate AND ActivityDate <= :r.endDate)))');
        s.openTasks = (Integer) taskOpen[0].get('c');

        // Completed Tasks completed in range
        String taskDoneWhere = ' IsDeleted = false AND Status = \'Completed\' ';
        if (ownerIds != null && !ownerIds.isEmpty()) taskDoneWhere += ' AND OwnerId IN :ownerIds ';
        List<AggregateResult> taskDone = Database.query('SELECT COUNT(Id) c FROM Task WHERE ' + taskDoneWhere +
            ' AND (ActivityDate != null AND ActivityDate >= :r.startDate AND ActivityDate <= :r.endDate)');
        s.completedTasks = (Integer) taskDone[0].get('c');

        // Events in range
        String eventWhere = ' IsDeleted = false ';
        if (ownerIds != null && !ownerIds.isEmpty()) eventWhere += ' AND OwnerId IN :ownerIds ';
        List<AggregateResult> evts = Database.query('SELECT COUNT(Id) c FROM Event WHERE ' + eventWhere +
            ' AND (StartDateTime != null AND StartDateTime >= :r.startDateTime AND StartDateTime <= :r.endDateTime)');
        s.events = (Integer) evts[0].get('c');

        return s;
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityMetrics getOpportunityMetricsFiltered(String timeframe, Id selectedUserId, String selectedPartner) {
        Set<Id> ownerIds = resolveOwnerIds(selectedUserId, selectedPartner);
        DateTimeRange r = computeRange(timeframe);
        OpportunityMetrics m = new OpportunityMetrics();

        // OPEN
        String openWhere = ' IsDeleted = false AND IsClosed = false ';
        if (ownerIds != null && !ownerIds.isEmpty()) openWhere += ' AND OwnerId IN :ownerIds ';
        // Consider CloseDate in/around range for open pipeline reporting (optional). We'll not restrict to range to show current pipeline.
        List<AggregateResult> openAgg = Database.query('SELECT COUNT(Id) c, SUM(Amount) a FROM Opportunity WHERE ' + openWhere);
        m.openCount = (Integer) openAgg[0].get('c');
        m.openAmount = (Decimal) (openAgg[0].get('a') == null ? 0 : openAgg[0].get('a'));

        // WON
        String wonWhere = ' IsDeleted = false AND IsClosed = true AND IsWon = true ';
        if (ownerIds != null && !ownerIds.isEmpty()) wonWhere += ' AND OwnerId IN :ownerIds ';
        wonWhere += ' AND CloseDate >= :r.startDate AND CloseDate <= :r.endDate ';
        List<AggregateResult> wonAgg = Database.query('SELECT COUNT(Id) c, SUM(Amount) a FROM Opportunity WHERE ' + wonWhere);
        m.wonCount = (Integer) wonAgg[0].get('c');
        m.wonAmount = (Decimal) (wonAgg[0].get('a') == null ? 0 : wonAgg[0].get('a'));

        // LOST
        String lostWhere = ' IsDeleted = false AND IsClosed = true AND IsWon = false ';
        if (ownerIds != null && !ownerIds.isEmpty()) lostWhere += ' AND OwnerId IN :ownerIds ';
        lostWhere += ' AND CloseDate >= :r.startDate AND CloseDate <= :r.endDate ';
        List<AggregateResult> lostAgg = Database.query('SELECT COUNT(Id) c, SUM(Amount) a FROM Opportunity WHERE ' + lostWhere);
        m.lostCount = (Integer) lostAgg[0].get('c');
        m.lostAmount = (Decimal) (lostAgg[0].get('a') == null ? 0 : lostAgg[0].get('a'));

        return m;
    }

    // ===== Helper: resolve owner Ids from user or partner =====
    private static Set<Id> resolveOwnerIds(Id selectedUserId, String selectedPartner) {
        if (selectedUserId != null) {
            return new Set<Id>{selectedUserId};
        }
        if (selectedPartner != null && selectedPartner.trim() != '') {
            Set<Id> ids = new Set<Id>();
            for (User u : [SELECT Id FROM User WHERE IsActive = true AND Partner__c = :selectedPartner LIMIT 50000]) {
                ids.add(u.Id);
            }
            return ids;
        }
        return null; // means "no filter"
    }

    // ===== Date helpers =====
    private class DateTimeRange {
        public Date startDate;
        public Date endDate;
        public Datetime startDateTime;
        public Datetime endDateTime;
        public DateTimeRange(Date s, Date e) {
            startDate = s; endDate = e;
            startDateTime = Datetime.newInstance(s.year(), s.month(), s.day());
            endDateTime = Datetime.newInstance(e.year(), e.month(), e.day(), 23, 59, 59);
        }
    }
    private static DateTimeRange computeRange(String timeframe) {
        if (String.isBlank(timeframe)) timeframe = 'ThisMonth';
        Date today = Date.today();

        if (timeframe == 'ThisWeek') {
            return new DateTimeRange(Date.today().toStartOfWeek(), Date.today().toStartOfWeek().addDays(6));
        } else if (timeframe == 'LastWeek') {
            Date start = Date.today().toStartOfWeek().addDays(-7);
            return new DateTimeRange(start, start.addDays(6));
        } else if (timeframe == 'ThisMonth') {
            Date s = Date.newInstance(today.year(), today.month(), 1);
            Date e = s.addMonths(1).addDays(-1);
            return new DateTimeRange(s, e);
        } else if (timeframe == 'LastMonth') {
            Date s = Date.newInstance(today.addMonths(-1).year(), today.addMonths(-1).month(), 1);
            Date e = s.addMonths(1).addDays(-1);
            return new DateTimeRange(s, e);
        } else if (timeframe == 'Last7Days') {
            return new DateTimeRange(today.addDays(-6), today);
        } else if (timeframe == 'Last30Days') {
            return new DateTimeRange(today.addDays(-29), today);
        } else if (timeframe == 'ThisQuarter') {
            Integer q = ((today.month() - 1) / 3) + 1;
            Integer startMonth = ((q - 1) * 3) + 1;
            Date s = Date.newInstance(today.year(), startMonth, 1);
            Date e = s.addMonths(3).addDays(-1);
            return new DateTimeRange(s, e);
        } else if (timeframe == 'LastQuarter') {
            Date shift = today.addMonths(-3);
            Integer q = ((shift.month() - 1) / 3) + 1;
            Integer startMonth = ((q - 1) * 3) + 1;
            Date s = Date.newInstance(shift.year(), startMonth, 1);
            Date e = s.addMonths(3).addDays(-1);
            return new DateTimeRange(s, e);
        } else {
            // default to ThisMonth
            Date s = Date.newInstance(today.year(), today.month(), 1);
            Date e = s.addMonths(1).addDays(-1);
            return new DateTimeRange(s, e);
        }
    }
}
