@isTest
public class TestDataHelper {
    public static String getValidOpportunityType() {
        Schema.DescribeFieldResult dfr = Opportunity.Opportunity_Type__c.getDescribe();
        List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
        if (!entries.isEmpty()) {
            return entries[0].getValue();
        }
        return 'Contract';
    }
}