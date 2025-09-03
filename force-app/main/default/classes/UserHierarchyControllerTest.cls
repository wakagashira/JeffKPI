@isTest
public class UserHierarchyControllerTest {

    @testSetup
    static void setupData() {
        // Create a role hierarchy
        UserRole ceoRole = new UserRole(Name = 'CEO');
        insert ceoRole;

        UserRole mgrRole = new UserRole(Name = 'Manager', ParentRoleId = ceoRole.Id);
        insert mgrRole;

        // Create users for the roles
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User ceoUser = new User(
            Alias = 'ceouser',
            Email = 'ceo@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CEO',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'ceo.user@example.com',
            UserRoleId = ceoRole.Id
        );
        insert ceoUser;

        User mgrUser = new User(
            Alias = 'mgruser',
            Email = 'mgr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'mgr.user@example.com',
            UserRoleId = mgrRole.Id
        );
        insert mgrUser;
    }

    @isTest
    static void testGetUserActivitySummary_NormalUser() {
        User normalUser = [SELECT Id FROM User WHERE Alias = 'mgruser' LIMIT 1];
        System.runAs(normalUser) {
            Test.startTest();
            List<UserHierarchyController.UserActivitySummary> results = UserHierarchyController.getUserActivitySummary();
            Test.stopTest();
            System.assert(!results.isEmpty(), 'Normal user should see hierarchy data');

            Boolean found = false;
            for (UserHierarchyController.UserActivitySummary r : results) {
                if (r.userId == UserInfo.getUserId()) {
                    found = true;
                    break;
                }
            }
            System.assertEquals(true, found, 'Results should include the running user');
        }
    }

    @isTest
    static void testGetUserActivitySummary_SysAdminSeesAll() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole dummyRole = [SELECT Id FROM UserRole LIMIT 1];

        User sysAdmin = new User(
            Alias = 'sysadm',
            Email = 'sysadmin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SysAdmin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'sysadmin.user@example.com',
            UserRoleId = dummyRole.Id
        );
        insert sysAdmin;

        System.runAs(sysAdmin) {
            Test.startTest();
            List<UserHierarchyController.UserActivitySummary> results = UserHierarchyController.getUserActivitySummary();
            Test.stopTest();
            System.assert(results.size() >= 2, 'SysAdmin should see all users, not just role hierarchy');

            Boolean found = false;
            for (UserHierarchyController.UserActivitySummary r : results) {
                if (r.userId == UserInfo.getUserId()) {
                    found = true;
                    break;
                }
            }
            System.assertEquals(true, found, 'Results should include the running SysAdmin');
        }
    }

    @isTest
    static void testGetUsersInMyHierarchy_NormalUser() {
        User normalUser = [SELECT Id FROM User WHERE Alias = 'mgruser' LIMIT 1];
        System.runAs(normalUser) {
            Test.startTest();
            List<User> users = UserHierarchyController.getUsersInMyHierarchy();
            Test.stopTest();
            System.assert(!users.isEmpty(), 'Hierarchy users should be returned for normal user');

            Boolean found = false;
            for (User u : users) {
                if (u.Id == UserInfo.getUserId()) {
                    found = true;
                    break;
                }
            }
            System.assertEquals(true, found, 'Users should include the running user');
        }
    }

    @isTest
    static void testGetUsersInMyHierarchy_SysAdminSeesAll() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole dummyRole = [SELECT Id FROM UserRole LIMIT 1];

        User sysAdmin = new User(
            Alias = 'sysadm2',
            Email = 'sysadmin2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SysAdmin2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'sysadmin2.user@example.com',
            UserRoleId = dummyRole.Id
        );
        insert sysAdmin;

        System.runAs(sysAdmin) {
            Test.startTest();
            List<User> users = UserHierarchyController.getUsersInMyHierarchy();
            Test.stopTest();
            System.assert(users.size() >= 2, 'SysAdmin should see all users across org');

            Boolean found = false;
            for (User u : users) {
                if (u.Id == UserInfo.getUserId()) {
                    found = true;
                    break;
                }
            }
            System.assertEquals(true, found, 'Users should include the running SysAdmin');
        }
    }
}
