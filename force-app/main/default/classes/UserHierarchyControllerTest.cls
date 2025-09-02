@isTest
private class UserHierarchyControllerTest {
    @testSetup
    static void setupData() {
        UserRole parentRole = new UserRole(Name='Parent Role');
        insert parentRole;
        UserRole childRole = new UserRole(Name='Child Role', ParentRoleId=parentRole.Id);
        insert childRole;

        Profile p = [SELECT Id FROM Profile LIMIT 1];

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

        insert new Task(OwnerId=childUser.Id, Subject='Test Call', Status='Completed', Priority='Normal', Type='Call', ActivityDate=Date.today());
        insert new Task(OwnerId=childUser.Id, Subject='Test Email', Status='Completed', Priority='Normal', Type='Email', ActivityDate=Date.today());
        insert new Event(OwnerId=childUser.Id, Subject='Test Meeting', StartDateTime=System.now().addMinutes(-5), EndDateTime=System.now().addMinutes(25));

        Account a = new Account(Name='Test Account');
        insert a;

        Opportunity o1 = new Opportunity(
            Name='Pipeline Opp', StageName='Prospecting', CloseDate=Date.today(),
            Amount=10000, AccountId=a.Id, OwnerId=childUser.Id,
            Opportunity_Type__c=TestDataHelper.getValidOpportunityType()
        );
        insert o1;
        Opportunity o2 = new Opportunity(
            Name='Closed Won Opp', StageName='Closed Won', CloseDate=Date.today(),
            Amount=5000, AccountId=a.Id, OwnerId=childUser.Id,
            Opportunity_Type__c=TestDataHelper.getValidOpportunityType()
        );
        insert o2;
    }

    @isTest static void testGetUsersInMyHierarchy() {
        User parent = [SELECT Id FROM User WHERE FirstName='Parent' LIMIT 1];
        System.runAs(parent) {
            List<User> users = UserHierarchyController.getUsersInMyHierarchy();
            System.assert(users.size() >= 1, 'Should return at least one user');
        }
    }

    @isTest static void testGetUserActivitySummary_Last7Days() {
        User parent = [SELECT Id FROM User WHERE FirstName='Parent' LIMIT 1];
        System.runAs(parent) {
            List<UserHierarchyController.UserActivitySummary> sums =
                UserHierarchyController.getUserActivitySummary('Last7Days');
            System.assert(!sums.isEmpty(), 'Summaries should be returned');
        }
    }

    @isTest static void testGetOpportunityMetrics_Last7Days() {
        User parent = [SELECT Id FROM User WHERE FirstName='Parent' LIMIT 1];
        System.runAs(parent) {
            UserHierarchyController.OpportunityMetrics m =
                UserHierarchyController.getOpportunityMetrics('Last7Days');
            System.assert(m != null, 'Metrics should not be null');
        }
    }
}