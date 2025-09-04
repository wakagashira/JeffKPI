@IsTest
private class JeffKPIControllerTest {
    @IsTest
    static void testGetters() {
        Account a = new Account(Name='Test Acct');
        insert a;

        Opportunity o1 = new Opportunity(
            Name='Opp Open',
            AccountId=a.Id,
            StageName='Prospecting',
            CloseDate=System.today().addDays(10),
            Amount=1000,
            Opportunity_Type__c='Project'
        );
        Opportunity o2 = new Opportunity(
            Name='Opp Won',
            AccountId=a.Id,
            StageName='Closed Won',
            CloseDate=System.today(),
            Amount=2000,
            Opportunity_Type__c='Project'
        );
        insert new List<Opportunity>{ o1, o2 };

        Test.startTest();
        JeffKPIController.FilterOptions fo = JeffKPIController.getFilterOptions();
        System.assertNotEquals(null, fo);
        List<JeffKPIController.UserKPI> users = JeffKPIController.getUserKpis(null, 30);
        System.assertNotEquals(null, users);
        Test.stopTest();
    }
}
