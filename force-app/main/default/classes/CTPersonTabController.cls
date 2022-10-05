public with sharing class CTPersonTabController {
    @AuraEnabled
    public static Person__c getPersonDetails(String personId){

        Person__c person = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c
        FROM Person__c
        WHERE Id =:personId];

        if(person != null){
            return person;
        }
        return null;
    }
}
