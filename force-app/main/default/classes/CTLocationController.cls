public with sharing class CTLocationController {
    public static List<Location__c> getRecentStatusChanges(){
        return [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c FROM Location__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
    }

    public static List<Location__c> searchLocations(String searchItem){
        searchItem = '%'+searchItem;
        return [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c
                    FROM Location__c 
                    WHERE Name LIKE:searchItem OR Pincode__c LIKE :searchItem OR Address__c LIKE :searchItem
                    ORDER BY Status_Update_Date__c DESC NULLS LAST];
    }

    public static Location__c getLocationById(String locationId){
        List<Location__c> ListaP = [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c
                                FROM Location__c 
                                WHERE Id =:locationId];        
        if(ListaP != null && ListaP.size() > 0 ){
            return ListaP[0];
        }
        return null;
    }

    public static void updateRedScore(Set<Id> locationIds){
        List<Location__c> locationToUpdate = new List<Location__c>();
        AggregateResult[] redPeoplePerLocation = [SELECT Location__c, COUNT(Id) total FROM Location_Tracing__c
        WHERE Person__r.Health_Status__c = 'Red'
        AND Visit_Date__c = LAST_N_DAYS :10
        AND Location__c IN : locationIds
        GROUP BY Location__c];

        for (AggregateResult ar : redPeoplePerLocation) {
            String locationId = String.valueOf(ar.get('Location__c'));
            Integer redScore = Integer.valueOf(ar.get('total'));
            String status = getStatus(redScore);
            locationToUpdate.add(new Location__c(Id=locationId, Red_Score__c=redScore, Status__c=status));
        }
        if(locationToUpdate != null && locationToUpdate.size() > 0){
            update locationToUpdate;
        }
        
    }

    public static String getStatus(Integer redScore){
        if(redScore == 0){
            return 'Green';
        } else if(redScore <= 5){
            return 'Yellow';
        } else if(redScore <= 10){
            return 'Orange';
        }else{
            return 'Red';
        }
    }

    public static Map<String, Integer> getStatusCount(){
        Map<String, Integer> statusAccount = new Map<String, Integer>();
        for (AggregateResult result: [SELECT Status__c, COUNT(Id) Locations FROM Location__c GROUP BY Status__c]) {
            statusAccount.put(String.valueOf(result.get('Status__c')),Integer.valueOf(result.get('Locations')));
        }
        return statusAccount;
    }

}
