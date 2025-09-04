@IsTest
private class JeffKPIControllerTest {
    @IsTest
    static void testGetKPIsAndFilters() {
        Id uid = UserInfo.getUserId();
        Date today = Date.today();

        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(Name='Open 1', StageName='Prospecting', CloseDate=today.addDays(15), Amount=1000, OwnerId=uid));
        opps.add(new Opportunity(Name='Won MTD', StageName='Closed Won', CloseDate=today, Amount=2000, OwnerId=uid));
        opps.add(new Opportunity(Name='Won Last Year', StageName='Closed Won', CloseDate=Date.newInstance(today.year()-1, today.month(), 1), Amount=3000, OwnerId=uid));
        insert opps;

        Test.startTest();
        List<JeffKPIController.KPIUser> kpis = JeffKPIController.getKPIs('MTD', null, 10);
        JeffKPIController.FilterOptions fo = JeffKPIController.getFilterOptions();
        Test.stopTest();

        System.assert(!kpis.isEmpty(), 'Expected at least one KPIUser returned');
        System.assertNotEquals(null, fo, 'FilterOptions should not be null');
        System.assert(!fo.timeframeOptions.isEmpty(), 'Timeframe options should exist');
    }
}
