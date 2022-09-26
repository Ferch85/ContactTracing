public with sharing class CTPersonTriggerHandler {
    public static void beforeInsertHandler(List<Person__c> newPersons){
        List<Person__c> correctPerson = new List<Person__c>();
        for(Person__c person : newPersons){
            person.Health_Status__c = 'Green';
            person.Token__c = CTPersonController.getToken(person.Mobile__c);
        }
    }
    public static void beforeUpdateHandler(List<Person__c> newPersons, Map<Id, Person__c> oldPersonsMap) {
        for (Person__c person : newPersons) {
            if (person.Health_Status__c != oldPersonsMap.get(person.Id).Health_Status__c) {
                person.Status_Update_Date__c = Date.today();
            }
        }
    }

    public static void afterUpdateHandler(List<Person__c> newRecords, Map<Id, Person__c> oldRecordsMap) {
        Set<Id> statusChange = new Set<Id>();
        Set<Id> redStatus = new Set<Id>();
        
        for(Person__c person : newRecords){
            if(person.Health_Status__c != oldRecordsMap.get(person.Id).Health_Status__c){
                statusChange.add(person.Id);
            }
            if (person.Health_Status__c == 'Red' && oldRecordsMap.get(person.Id).Health_Status__c != 'Red') {
                redStatus.add(person.Id);
            }
        }       
        
        Set<Id> alreadyProcessed = new Set<Id>();
        alreadyProcessed.addAll(redStatus);

        
        Set<Id> orangeStatus = new Set<Id>();
        Set<Id> yellowStatus = new Set<Id>();

        List<Person__c> personToUpdate = new List<Person__c>();


        // lets add cohanitants
        orangeStatus.addAll(CTPersonController.getCohabitants(redStatus, alreadyProcessed));

        // lets add primaryContacts
        Set<Id> primaryContacts = CTPersonController.getPrimaryContacts(redStatus, alreadyProcessed);
        orangeStatus.addAll(primaryContacts);        

        // lets add neighbors
        yellowStatus.addAll(CTPersonController.getNeighbours(redStatus, alreadyProcessed));
        
        // lets add SecondaryContacts
        yellowStatus.addAll(CTPersonController.getSecondaryContacts(primaryContacts, alreadyProcessed));        

        for (Id pid : orangeStatus) {
            personToUpdate.add(new Person__c(Id=pid, Health_Status__c='Orange'));
        }

        for (Id pid : yellowStatus) {
            personToUpdate.add(new Person__c(Id=pid, Health_Status__c='Yellow'));
        }
        if(personToUpdate.size() > 0){
            update personToUpdate;
        }
        
        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByPersonIds(statusChange);

        if(locationTraces != null && locationTraces.size() > 0){
            Set<Id> locationIds = new Set<Id>();
            for (Location_Tracing__c trace : locationTraces) {
                locationIds.add(trace.Location__c);
            }
            CTLocationController.updateRedScore(locationIds);

        }
        

    }
}