public with sharing class UserHierarchyController {

    public class UserActivitySummary {
        @AuraEnabled public Id userId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer callCount;
        @AuraEnabled public Integer meetingCount;
    }

    @AuraEnabled(cacheable=true)
    public static List<UserActivitySummary> getUserActivitySummary() {
        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId == null) {
            return new List<UserActivitySummary>();
        }

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        Map<Id, String> userMap = new Map<Id, String>();
        for (User u : [
            SELECT Id, Name
            FROM User
            WHERE UserRoleId IN :roleIds AND IsActive = true
        ]) {
            userMap.put(u.Id, u.Name);
        }
        if (userMap.isEmpty()) return new List<UserActivitySummary>();

        Date startDateTasks = Date.today().addDays(-30);
        Datetime startDateEvents = System.now().addDays(-30);

        Map<Id, Integer> callCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId ownerId, COUNT(Id) cnt
            FROM Task
            WHERE OwnerId IN :userMap.keySet()
            AND Type = 'Call'
            AND ActivityDate >= :startDateTasks
            GROUP BY OwnerId
        ]) {
            callCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        Map<Id, Integer> meetingCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId ownerId, COUNT(Id) cnt
            FROM Event
            WHERE OwnerId IN :userMap.keySet()
            AND StartDateTime >= :startDateEvents
            GROUP BY OwnerId
        ]) {
            meetingCounts.put((Id)ar.get('ownerId'), (Integer)ar.get('cnt'));
        }

        List<UserActivitySummary> results = new List<UserActivitySummary>();
        for (Id uid : userMap.keySet()) {
            UserActivitySummary uas = new UserActivitySummary();
            uas.userId = uid;
            uas.name = userMap.get(uid);
            uas.callCount = callCounts.containsKey(uid) ? callCounts.get(uid) : 0;
            uas.meetingCount = meetingCounts.containsKey(uid) ? meetingCounts.get(uid) : 0;
            results.add(uas);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersInMyHierarchy() {
        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId == null) {
            return new List<User>();
        }

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        return [
            SELECT Id, Name, FirstName, LastName, Email, Title, UserRole.Name
            FROM User
            WHERE UserRoleId IN :roleIds
            AND IsActive = true
            ORDER BY Name
        ];
    }

    private static void collectChildRoles(Id parentRoleId, Set<Id> roleIds) {
        for (UserRole ur : [
            SELECT Id 
            FROM UserRole 
            WHERE ParentRoleId = :parentRoleId
        ]) {
            if (!roleIds.contains(ur.Id)) {
                roleIds.add(ur.Id);
                collectChildRoles(ur.Id, roleIds);
            }
        }
    }
}
