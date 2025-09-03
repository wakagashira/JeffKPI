public with sharing class UserHierarchyController {

    public class UserActivitySummary {
        @AuraEnabled public Id userId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer callCount;
        @AuraEnabled public Integer meetingCount;
        @AuraEnabled public String partnerName;
    }

    @AuraEnabled(cacheable=true)
    public static List<UserActivitySummary> getUserActivitySummary(String timeFrame) {
        Set<Id> roleIds = getEffectiveRoleIds();
        if (roleIds.isEmpty()) {
            return new List<UserActivitySummary>();
        }

        // Get date range from timeFrame
        Map<String, DateTime> range = getDateRange(timeFrame);

        // Query calls (Tasks with subtype Call)
        Map<Id, Integer> callCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId ownerId, COUNT(Id) cnt
            FROM Task
            WHERE TaskSubtype = 'Call'
              AND ActivityDate >= :range.get('start').date()
              AND ActivityDate < :range.get('end').date()
              AND Owner.UserRoleId IN :roleIds
            GROUP BY OwnerId
        ]) {
            callCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        // Query meetings (Events)
        Map<Id, Integer> meetingCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId ownerId, COUNT(Id) cnt
            FROM Event
            WHERE StartDateTime >= :range.get('start')
              AND StartDateTime < :range.get('end')
              AND Owner.UserRoleId IN :roleIds
            GROUP BY OwnerId
        ]) {
            meetingCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        // Fetch users in scope + always include current user
        List<User> users = [SELECT Id, Name, Partner__c FROM User WHERE UserRoleId IN :roleIds OR Id = :UserInfo.getUserId()];

        List<UserActivitySummary> results = new List<UserActivitySummary>();
        for (User u : users) {
            UserActivitySummary uas = new UserActivitySummary();
            uas.userId = u.Id;
            uas.name = u.Name;
            uas.partnerName = (String)u.get('Partner__c');
            uas.callCount = callCounts.containsKey(u.Id) ? callCounts.get(u.Id) : 0;
            uas.meetingCount = meetingCounts.containsKey(u.Id) ? meetingCounts.get(u.Id) : 0;
            results.add(uas);
        }

        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersInMyHierarchy() {
        Set<Id> roleIds = getEffectiveRoleIds();
        List<User> users = new List<User>();
        if (!roleIds.isEmpty()) {
            users = [SELECT Id, Name, UserRoleId FROM User WHERE UserRoleId IN :roleIds];
        }
        // Always include self
        Boolean found = false;
        for (User u : users) {
            if (u.Id == UserInfo.getUserId()) {
                found = true;
                break;
            }
        }
        if (!found) {
            users.add([SELECT Id, Name, UserRoleId FROM User WHERE Id = :UserInfo.getUserId()]);
        }
        return users;
    }

    /**
     * Returns date range for given time frame
     */
    private static Map<String, DateTime> getDateRange(String timeFrame) {
        Date today = Date.today();
        DateTime startDt;
        DateTime endDt;

        if (timeFrame == 'Today') {
            startDt = DateTime.newInstance(today, Time.newInstance(0,0,0,0));
            endDt   = startDt.addDays(1);
        } else if (timeFrame == 'Yesterday') {
            startDt = DateTime.newInstance(today.addDays(-1), Time.newInstance(0,0,0,0));
            endDt   = DateTime.newInstance(today, Time.newInstance(0,0,0,0));
        } else if (timeFrame == 'ThisWeek') {
            startDt = DateTime.newInstance(today.toStartOfWeek(), Time.newInstance(0,0,0,0));
            endDt   = startDt.addDays(7);
        } else if (timeFrame == 'LastWeek') {
            startDt = DateTime.newInstance(today.toStartOfWeek().addDays(-7), Time.newInstance(0,0,0,0));
            endDt   = DateTime.newInstance(today.toStartOfWeek(), Time.newInstance(0,0,0,0));
        } else if (timeFrame == 'ThisMonth') {
            startDt = DateTime.newInstance(Date.newInstance(today.year(), today.month(), 1), Time.newInstance(0,0,0,0));
            endDt   = startDt.addMonths(1);
        } else if (timeFrame == 'LastMonth') {
            startDt = DateTime.newInstance(Date.newInstance(today.year(), today.month(), 1).addMonths(-1), Time.newInstance(0,0,0,0));
            endDt   = DateTime.newInstance(Date.newInstance(today.year(), today.month(), 1), Time.newInstance(0,0,0,0));
        } else if (timeFrame == 'ThisYear') {
            startDt = DateTime.newInstance(Date.newInstance(today.year(), 1, 1), Time.newInstance(0,0,0,0));
            endDt   = startDt.addYears(1);
        } else {
            // Default = last 365 days
            startDt = DateTime.now().addDays(-365);
            endDt   = DateTime.now().addDays(1);
        }
        return new Map<String, DateTime>{ 'start' => startDt, 'end' => endDt };
    }

    /**
     * Returns the set of roleIds the current user should see.
     * - SysAdmin → ALL roles
     * - Others → their role + child roles
     */
    private static Set<Id> getEffectiveRoleIds() {
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name;

        if (profileName == 'System Administrator') {
            return new Map<Id, UserRole>([SELECT Id FROM UserRole]).keySet();
        }

        Set<Id> roleIds = new Set<Id>();
        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId != null) {
            collectChildRoles(myRoleId, roleIds);
            roleIds.add(myRoleId);
        }
        return roleIds;
    }

    private static void collectChildRoles(Id parentRoleId, Set<Id> allRoleIds) {
        Map<Id, List<UserRole>> rolesByParent = new Map<Id, List<UserRole>>();
        for (UserRole role : [SELECT Id, ParentRoleId FROM UserRole]) {
            if (!rolesByParent.containsKey(role.ParentRoleId)) {
                rolesByParent.put(role.ParentRoleId, new List<UserRole>());
            }
            rolesByParent.get(role.ParentRoleId).add(role);
        }
        addChildren(parentRoleId, allRoleIds, rolesByParent);
    }

    private static void addChildren(Id parentRoleId, Set<Id> allRoleIds, Map<Id, List<UserRole>> rolesByParent) {
        if (rolesByParent.containsKey(parentRoleId)) {
            for (UserRole child : rolesByParent.get(parentRoleId)) {
                if (!allRoleIds.contains(child.Id)) {
                    allRoleIds.add(child.Id);
                    addChildren(child.Id, allRoleIds, rolesByParent);
                }
            }
        }
    }
}
