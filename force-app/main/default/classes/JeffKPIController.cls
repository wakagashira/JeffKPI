// v4.1.6 — Jeff KPI Controller (no '%' operator; safe decimal calc)
public with sharing class JeffKPIController {
    public class KPI {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Integer openOpps;
        @AuraEnabled public Integer overdueOpps;
        @AuraEnabled public Integer wonOpps;
        @AuraEnabled public Integer lostOpps;
        @AuraEnabled public Integer totalOpps;
        @AuraEnabled public Decimal winRate; // percentage (0-100), 0 scale
    }

    @AuraEnabled(cacheable=true)
    public static List<KPI> getKPIs(Date startDate, Date endDate, Id userId) {
        if (startDate == null) startDate = System.today().addDays(-90);
        if (endDate == null) endDate = System.today();

        List<Id> ownerIds = new List<Id>();
        if (userId != null) {
            ownerIds.add(userId);
        } else {
            ownerIds.add(UserInfo.getUserId());
        }

        Map<Id, KPI> byOwner = new Map<Id, KPI>();
        Map<Id, User> uMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :ownerIds]);

        for (Id oid : ownerIds) {
            KPI k = new KPI();
            k.userId = oid;
            k.userName = uMap.containsKey(oid) ? uMap.get(oid).Name : String.valueOf(oid);
            k.openOpps = 0;
            k.overdueOpps = 0;
            k.wonOpps = 0;
            k.lostOpps = 0;
            k.totalOpps = 0;
            k.winRate = 0;
            byOwner.put(oid, k);
        }

        List<Opportunity> opps = [
            SELECT Id, OwnerId, IsClosed, IsWon, CloseDate
            FROM Opportunity
            WHERE OwnerId IN :ownerIds
            AND CloseDate >= :startDate
            AND CloseDate <= :endDate
        ];

        Date today = System.today();
        for (Opportunity o : opps) {
            KPI k = byOwner.get(o.OwnerId);
            if (k == null) continue;
            k.totalOpps++;
            if (!o.IsClosed) {
                k.openOpps++;
                if (o.CloseDate != null && o.CloseDate < today) {
                    k.overdueOpps++;
                }
            } else {
                if (o.IsWon) {
                    k.wonOpps++;
                } else {
                    k.lostOpps++;
                }
            }
        }

        for (Id oid : byOwner.keySet()) {
            KPI k = byOwner.get(oid);
            if (k.totalOpps > 0) {
                // Safe decimal division -> percentage
                Decimal wonD = Decimal.valueOf(k.wonOpps);
                Decimal totD = Decimal.valueOf(k.totalOpps);
                k.winRate = (wonD.divide(totD, 6)) * 100;
                // normalize scale to whole number for display thresholds
                k.winRate = k.winRate.setScale(0, RoundingMode.HALF_UP);
            } else {
                k.winRate = 0;
            }
        }

        return new List<KPI>(byOwner.values());
    }
}
