public with sharing class UserHierarchyController {

    public class UserActivitySummary {
        @AuraEnabled public Id userId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer callCount;
        @AuraEnabled public Integer meetingCount;
        @AuraEnabled public String partnerName;
    }

    @AuraEnabled(cacheable=true)
    public static List<UserActivitySummary> getUserActivitySummary() {
        Id myRoleId = getEffectiveRoleId();
        if (myRoleId == null) {
            return new List<UserActivitySummary>();
        }

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        Map<Id, User> usersById = new Map<Id, User>(
            [SELECT Id, Name, Partner__c
             FROM User
             WHERE UserRoleId IN :roleIds]
        );

        List<UserActivitySummary> results = new List<UserActivitySummary>();

        for (User u : usersById.values()) {
            UserActivitySummary uas = new UserActivitySummary();
            uas.userId = u.Id;
            uas.name = u.Name;
            uas.partnerName = (String)u.get('Partner__c');
            uas.callCount = 0;
            uas.meetingCount = 0;
            results.add(uas);
        }

        return results;
    }

    /**
     * Re-added for test compatibility: returns all Users in current hierarchy.
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersInMyHierarchy() {
        Id myRoleId = getEffectiveRoleId();
        if (myRoleId == null) return new List<User>();

        Set<Id> roleIds = new Set<Id>();
        collectChildRoles(myRoleId, roleIds);
        roleIds.add(myRoleId);

        return [SELECT Id, Name, UserRoleId FROM User WHERE UserRoleId IN :roleIds];
    }

    /**
     * Returns the effective roleId for the current user.
     * If user is SysAdmin, return CEO role Id instead.
     */
    private static Id getEffectiveRoleId() {
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name;

        if (profileName == 'System Administrator') {
            // CEO role lookup
            UserRole ceoRole = [
                SELECT Id FROM UserRole WHERE Name = 'CEO' LIMIT 1
            ];
            return ceoRole.Id;
        } else {
            return UserInfo.getUserRoleId();
        }
    }

    /**
     * Optimized: Avoid SOQL inside recursion. Build a map of roles once, recurse in memory.
     */
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
