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
        Set<Id> roleIds = getEffectiveRoleIds();

        List<User> users = new List<User>();
        if (!roleIds.isEmpty()) {
            users = [SELECT Id, Name, Partner__c FROM User WHERE UserRoleId IN :roleIds];
        }

        // Always include the current user if not already present
        if (!users.isEmpty()) {
            Boolean found = false;
            for (User u : users) {
                if (u.Id == UserInfo.getUserId()) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                users.add([SELECT Id, Name, Partner__c FROM User WHERE Id = :UserInfo.getUserId()]);
            }
        } else {
            users.add([SELECT Id, Name, Partner__c FROM User WHERE Id = :UserInfo.getUserId()]);
        }

        List<UserActivitySummary> results = new List<UserActivitySummary>();
        for (User u : users) {
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

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersInMyHierarchy() {
        Set<Id> roleIds = getEffectiveRoleIds();

        List<User> users = new List<User>();
        if (!roleIds.isEmpty()) {
            users = [SELECT Id, Name, UserRoleId FROM User WHERE UserRoleId IN :roleIds];
        }

        // Always include self if not already present
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
     * Returns the set of roleIds the current user should see.
     * - SysAdmin → ALL roles
     * - Others → their role + child roles
     */
    private static Set<Id> getEffectiveRoleIds() {
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name;

        // SysAdmin → all roles
        if (profileName == 'System Administrator') {
            return new Map<Id, UserRole>(
                [SELECT Id FROM UserRole]
            ).keySet();
        }

        // Others → current role + children
        Set<Id> roleIds = new Set<Id>();
        Id myRoleId = UserInfo.getUserRoleId();
        if (myRoleId != null) {
            collectChildRoles(myRoleId, roleIds);
            roleIds.add(myRoleId);
        }
        return roleIds;
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
