@IsTest
private class JeffKPIControllerTest {
    @IsTest
    static void testGetters() {
        // Create supporting Account
        Account a = new Account(Name = 'Test Account');
        insert a;

        // Discover valid stage names for open, won, and closed-lost
        String openStage = null, wonStage = null, lostStage = null;
        for (OpportunityStage s : [SELECT MasterLabel, IsClosed, IsWon FROM OpportunityStage WHERE IsActive = true]) {
            if (!s.IsClosed && openStage == null) openStage = s.MasterLabel;
            if (s.IsWon && wonStage == null) wonStage = s.MasterLabel;
            if (s.IsClosed && !s.IsWon && lostStage == null) lostStage = s.MasterLabel;
        }
        System.assertNotEquals(null, openStage, 'Need at least one open stage');
        System.assertNotEquals(null, wonStage, 'Need at least one won stage');
        System.assertNotEquals(null, lostStage, 'Need at least one closed-lost stage');

        // Helper to set required custom fields, if they exist and are required
        Opportunity baseOpp = new Opportunity();
        baseOpp.put('Name', 'BASE');
        baseOpp.put('StageName', openStage);
        baseOpp.put('CloseDate', System.today());
        baseOpp.put('AccountId', a.Id);
        // Opportunistically set a commonly-required custom field if present in target org
        try {
            Map<String, Schema.SObjectField> fmap = Schema.SObjectType.Opportunity.fields.getMap();
            if (fmap.containsKey('Opportunity_Type__c')) {
                Schema.DescribeFieldResult d = fmap.get('Opportunity_Type__c').getDescribe();
                if (d.getType() == Schema.DisplayType.Picklist && d.getPicklistValues().size() > 0) {
                    baseOpp.put('Opportunity_Type__c', d.getPicklistValues()[0].getValue());
                } else {
                    baseOpp.put('Opportunity_Type__c', 'Automation');
                }
            }
        } catch (Exception e) {
            // ignore dynamic-set issues for orgs without the field
        }

        // Create records: 2 won, 1 lost, 1 open overdue
        List<Opportunity> toIns = new List<Opportunity>();
        // Open overdue
        Opportunity o1 = baseOpp.clone(false, true, false, false);
        o1.Name = 'Open Overdue';
        o1.StageName = openStage;
        o1.CloseDate = System.today().addDays(-1);
        toIns.add(o1);

        // Won #1
        Opportunity o2 = baseOpp.clone(false, true, false, false);
        o2.Name = 'Won 1';
        o2.StageName = wonStage;
        o2.CloseDate = System.today();
        toIns.add(o2);

        // Won #2
        Opportunity o3 = baseOpp.clone(false, true, false, false);
        o3.Name = 'Won 2';
        o3.StageName = wonStage;
        o3.CloseDate = System.today();
        toIns.add(o3);

        // Lost
        Opportunity o4 = baseOpp.clone(false, true, false, false);
        o4.Name = 'Lost 1';
        o4.StageName = lostStage;
        o4.CloseDate = System.today();
        toIns.add(o4);

        insert toIns;

        Test.startTest();
        List<JeffKPIController.KPI> res = JeffKPIController.getKPIs(System.today().addDays(-30), System.today().addDays(30), UserInfo.getUserId());
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Expect one KPI row for current user');
        JeffKPIController.KPI k = res[0];
        System.assertEquals(4, k.totalOpps, 'Total opps should be 4');
        System.assertEquals(1, k.overdueOpps, 'Overdue should be 1');
        System.assertEquals(2, k.wonOpps, 'Won should be 2');
        System.assertEquals(1, k.lostOpps, 'Lost should be 1');
        System.assertEquals(50, k.winRate, 'Win rate should be 50%');
    }
}
