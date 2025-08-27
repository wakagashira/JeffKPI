public with sharing class UserHierarchyController {
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
