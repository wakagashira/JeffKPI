@isTest
public class UserHierarchyControllerTest {

    @testSetup
    static void setupData() {
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());

        // Create a role hierarchy
        UserRole ceoRole = new UserRole(Name = 'CEO');
        insert ceoRole;

        UserRole mgrRole = new UserRole(Name = 'Manager', ParentRoleId = ceoRole.Id);
        insert mgrRole;

        // Create users for the roles
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User ceoUser = new User(
            Alias = 'ceouser',
            Email = 'ceo' + uniqueSuffix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CEO',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'ceo.user.' + uniqueSuffix + '@example.com',
            UserRoleId = ceoRole.Id
        );
        insert ceoUser;

        User mgrUser = new User(
            Alias = 'mgruser',
            Email = 'mgr' + uniqueSuffix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'mgr.user.' + uniqueSuffix + '@example.com',
            UserRoleId = mgrRole.Id
        );
        insert mgrUser;
    }

    @isTest
    static void testGetUserActivitySummary_NormalUser() {
        User normalUser = [SELECT Id FROM User WHERE Alias = 'mgruser' LIMIT 1];
        System.runAs(normalUser) {
            Test.startTest();
            List<UserHierarchyController.UserActivitySummary> results =
                UserHierarchyController.getUserActivitySummary('ThisMonth');
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
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User sysAdmin = new User(
            Alias = 'sysadm',
            Email = 'sysadmin' + uniqueSuffix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SysAdmin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'sysadmin.user.' + uniqueSuffix + '@example.com'
            // No UserRoleId for SysAdmin
        );
        insert sysAdmin;

        System.runAs(sysAdmin) {
            Test.startTest();
            List<UserHierarchyController.UserActivitySummary> results =
                UserHierarchyController.getUserActivitySummary('ThisMonth');
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
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User sysAdmin = new User(
            Alias = 'sysadm2',
            Email = 'sysadmin2_' + uniqueSuffix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SysAdmin2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'sysadmin2.user.' + uniqueSuffix + '@example.com'
            // No UserRoleId for SysAdmin
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

    @isTest
    static void testTimeFrameCounts() {
        User normalUser = [SELECT Id FROM User WHERE Alias = 'mgruser' LIMIT 1];
        System.runAs(normalUser) {
            // Create a call task for this month
            Task t = new Task(
                OwnerId = normalUser.Id,
                Subject = 'Test Call',
                TaskSubtype = 'Call',
                ActivityDate = Date.today()
            );
            insert t;

            // Create a meeting event for this month
            Event e = new Event(
                OwnerId = normalUser.Id,
                Subject = 'Test Meeting',
                StartDateTime = System.now().addHours(1),
                EndDateTime = System.now().addHours(2)
            );
            insert e;

            Test.startTest();
            List<UserHierarchyController.UserActivitySummary> results =
                UserHierarchyController.getUserActivitySummary('ThisMonth');
            Test.stopTest();

            Boolean found = false;
            Integer calls = 0;
            Integer meetings = 0;
            for (UserHierarchyController.UserActivitySummary r : results) {
                if (r.userId == UserInfo.getUserId()) {
                    found = true;
                    calls = r.callCount;
                    meetings = r.meetingCount;
                    break;
                }
            }
            System.assertEquals(true, found, 'Results should include the running user');
            System.assert(calls >= 1, 'Call count should reflect inserted Task');
            System.assert(meetings >= 1, 'Meeting count should reflect inserted Event');
        }
    }
}
