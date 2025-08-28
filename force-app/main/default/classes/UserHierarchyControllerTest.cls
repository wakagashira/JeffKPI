@isTest
private class UserHierarchyControllerTest {
    @testSetup
    static void setupData() {
        UserRole parentRole = new UserRole(Name='Parent Role');
        insert parentRole;
        UserRole childRole = new UserRole(Name='Child Role', ParentRoleId=parentRole.Id);
        insert childRole;

        // Some orgs don't have "Standard User" visible; fallback to first profile
        Profile p;
        List<Profile> ps = [SELECT Id, Name FROM Profile WHERE Name='Standard User' LIMIT 1];
        if (ps.isEmpty()) {
            p = [SELECT Id FROM Profile LIMIT 1];
        } else {
            p = ps[0];
        }

        User parentUser = new User(
            FirstName='Parent', LastName='User', Email='parentuser@test.com',
            Username='parentuser' + System.currentTimeMillis() + '@test.com',
            Alias='parusr', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            ProfileId=p.Id, UserRoleId=parentRole.Id
        );
        insert parentUser;

        User childUser = new User(
            FirstName='Child', LastName='User', Email='childuser@test.com',
            Username='childuser' + System.currentTimeMillis() + '@test.com',
            Alias='chiusr', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            ProfileId=p.Id, UserRoleId=childRole.Id
        );
        insert childUser;

        // Activities
        insert new Task(OwnerId=childUser.Id, Subject='Test Call', Status='Completed', Priority='Normal', Type='Call', ActivityDate=Date.today());
        insert new Task(OwnerId=childUser.Id, Subject='Test Email', Status='Completed', Priority='Normal', Type='Email', ActivityDate=Date.today());
        insert new Event(OwnerId=childUser.Id, Subject='Test Meeting', StartDateTime=System.now().addMinutes(-5), EndDateTime=System.now().addMinutes(25));

        // Account and Opportunities
        Account a = new Account(Name='Test Account');
        insert a;

        Opportunity o1 = new Opportunity(Name='Pipeline Opp', StageName='Prospecting', CloseDate=Date.today(), Amount=10000, AccountId=a.Id, OwnerId=childUser.Id);
        insert o1;
        Opportunity o2 = new Opportunity(Name='Closed Won Opp', StageName='Closed Won', CloseDate=Date.today(), Amount=5000, AccountId=a.Id, OwnerId=childUser.Id);
        insert o2;
    }

    @isTest
    static void testGetUsersInMyHierarchy() {
        User parent = [SELECT Id FROM User WHERE FirstName='Parent' LIMIT 1];
        System.runAs(parent) {
            Test.startTest();
            List<User> users = UserHierarchyController.getUsersInMyHierarchy();
            Test.stopTest();
            System.assert(users.size() >= 1, 'Should return at least one user');
        }
    }

    @isTest
    static void testGetUserActivitySummary_Last7Days() {
        User parent = [SELECT Id FROM User WHERE FirstName='Parent' LIMIT 1];
        System.runAs(parent) {
            Test.startTest();
            List<UserHierarchyController.UserActivitySummary> sums =
                UserHierarchyController.getUserActivitySummary('Last7Days');
            Test.stopTest();
            System.assert(!sums.isEmpty(), 'Summaries should be returned');
            Boolean hasActivity = false;
            for (UserHierarchyController.UserActivitySummary s : sums) {
                if (s.callCount > 0 || s.emailCount > 0 || s.meetingCount > 0) {
                    hasActivity = true; break;
                }
            }
            System.assertEquals(true, hasActivity, 'Expected at least one activity count > 0');
        }
    }

    @isTest
    static void testGetOpportunityMetrics_Last7Days() {
        User parent = [SELECT Id FROM User WHERE FirstName='Parent' LIMIT 1];
        System.runAs(parent) {
            Test.startTest();
            UserHierarchyController.OpportunityMetrics m =
                UserHierarchyController.getOpportunityMetrics('Last7Days');
            Test.stopTest();
            System.assert(m != null, 'Metrics should not be null');
            System.assert(m.pipelineValue >= 0, 'Pipeline value should be non-negative');
            System.assert(m.closedWonCount >= 0, 'Closed Won count non-negative');
            System.assert(m.createdCount >= 0, 'Created count non-negative');
        }
    }
}