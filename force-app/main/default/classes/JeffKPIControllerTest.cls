@isTest
public class JeffKPIControllerTest {
    @testSetup
    static void setupData() {
        // Create 2 test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u1 = new User(
            Alias = 'u1test',
            Email = 'u1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'One',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            UserName = 'u1' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
        insert u1;
        
        User u2 = new User(
            Alias = 'u2test',
            Email = 'u2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Two',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            UserName = 'u2' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            Partner__c = 'TestPartner'
        );
        insert u2;

        // Create Opportunities
        Opportunity o1 = new Opportunity(
            Name = 'Test Opp Open',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            OwnerId = u1.Id,
            Amount = 1000
        );
        insert o1;

        Opportunity o2 = new Opportunity(
            Name = 'Test Opp Won',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            OwnerId = u2.Id,
            Amount = 2000
        );
        insert o2;

        // Create Task
        Task t = new Task(
            Subject = 'Test Task',
            OwnerId = u1.Id,
            ActivityDate = Date.today(),
            Status = 'Not Started'
        );
        insert t;

        // Create Event
        Event e = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            OwnerId = u2.Id
        );
        insert e;
    }

    @isTest
    static void testControllerMethods() {
        // Options
        List<JeffKPIController.Option> users = JeffKPIController.getUserOptions();
        System.assertNotEquals(0, users.size(), 'Should return users');

        List<JeffKPIController.Option> partners = JeffKPIController.getPartnerOptions();
        System.assertNotEquals(null, partners, 'Partner list should not be null');

        // Legacy no-filter calls
        JeffKPIController.UserActivitySummary act = JeffKPIController.getUserActivitySummary('ThisMonth');
        System.assertNotEquals(null, act);

        JeffKPIController.OpportunityMetrics opp = JeffKPIController.getOpportunityMetrics('ThisMonth');
        System.assertNotEquals(null, opp);

        // Filtered calls by user
        JeffKPIController.UserActivitySummary act2 = JeffKPIController.getUserActivitySummaryFiltered('ThisMonth', users[0].value, null);
        System.assertNotEquals(null, act2);

        JeffKPIController.OpportunityMetrics opp2 = JeffKPIController.getOpportunityMetricsFiltered('ThisMonth', users[0].value, null);
        System.assertNotEquals(null, opp2);

        // Filtered calls by partner
        if (!partners.isEmpty()) {
            JeffKPIController.UserActivitySummary act3 = JeffKPIController.getUserActivitySummaryFiltered('ThisMonth', null, partners[0].value);
            System.assertNotEquals(null, act3);

            JeffKPIController.OpportunityMetrics opp3 = JeffKPIController.getOpportunityMetricsFiltered('ThisMonth', null, partners[0].value);
            System.assertNotEquals(null, opp3);
        }
    }
}
