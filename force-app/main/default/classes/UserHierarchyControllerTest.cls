@isTest
private class UserHierarchyControllerTest {
    @testSetup
    static void setupData() {
        UserRole parentRole = new UserRole(Name='Parent Role');
        insert parentRole;

        UserRole childRole = new UserRole(Name='Child Role', ParentRoleId=parentRole.Id);
        insert childRole;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User parentUser = new User(
            FirstName = 'Parent',
            LastName = 'User',
            Email = 'parentuser@test.com',
            Username = 'parentuser@test.com.' + System.currentTimeMillis(),
            Alias = 'parusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = parentRole.Id
        );
        insert parentUser;

        User childUser = new User(
            FirstName = 'Child',
            LastName = 'User',
            Email = 'childuser@test.com',
            Username = 'childuser@test.com.' + System.currentTimeMillis(),
            Alias = 'chiusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = childRole.Id
        );
        insert childUser;
    }

    @isTest
    static void testGetUsersInMyHierarchy() {
        User parent = [SELECT Id FROM User WHERE FirstName = 'Parent' LIMIT 1];
        System.runAs(parent) {
            Test.startTest();
            List<User> results = UserHierarchyController.getUsersInMyHierarchy();
            Test.stopTest();

            System.assertNotEquals(0, results.size(), 'Users should be returned');

            Boolean childFound = false;
            for (User u : results) {
                if (u.FirstName == 'Child') {
                    childFound = true;
                    break;
                }
            }
            System.assert(childFound, 'Child user should be included');
        }
    }
}
