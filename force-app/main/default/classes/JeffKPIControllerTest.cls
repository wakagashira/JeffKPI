@IsTest
private class JeffKPIControllerTest {
    @IsTest
    static void testFiltersAndKPIs() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Date today = Date.today();
        Opportunity o1 = new Opportunity(Name='Opp1', StageName='Prospecting', CloseDate=today.addDays(10), Amount=500, OwnerId=u.Id);
        Opportunity o2 = new Opportunity(Name='Opp2', StageName='Closed Won', CloseDate=today, Amount=1000, OwnerId=u.Id);
        insert new List<Opportunity>{o1,o2};

        Test.startTest();
        JeffKPIController.FilterOptions fo = JeffKPIController.getFilterOptions();
        System.assertNotEquals(null, fo);
        List<JeffKPIController.KPIUser> kpis = JeffKPIController.getKPIs('MTD', null, null, 10);
        System.assert(!kpis.isEmpty(), 'Expected KPI rows');
        Test.stopTest();
    }
}