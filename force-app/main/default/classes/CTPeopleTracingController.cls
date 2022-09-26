public with sharing class CTPeopleTracingController {
    public static List<People_Tracing__c> getTraces(String recordId) {
        return [SELECT Id, Contact_Date__c, Person_1__c, Person_1__r.Health_Status__c, Person_1__r.Token__c, Person_2__c, Person_2__r.Health_Status__c, Person_2__r.Token__c 
                FROM People_Tracing__c
                WHERE Person_1__c =:recordId 
                        OR Person_2__c =:recordId
                ORDER BY Contact_Date__c DESC];
    }

    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> peopleTraces){
        Set<Id> personsId = new Set<Id>();        

        for(People_Tracing__c people: peopleTraces){
            personsId.add(people.Person_1__c);
            personsId.add(people.Person_2__c);
        }

        List<People_Tracing__c> duplicates = new List<People_Tracing__c>();

        Map<Id, Set<Id>> mapExistingRecord = new Map<Id, Set<Id>>();

        List<People_Tracing__c> existingRecords = [SELECT Id, Person_1__c, Person_2__c 
                                    FROM People_Tracing__c
                                    WHERE Person_1__c IN: personsId
                                    AND Person_2__c IN: personsId];

        if(existingRecords != null && existingRecords.size() > 0){
            for (People_Tracing__c person : existingRecords) {
                if(!mapExistingRecord.containsKey(person.Person_1__c)){
                    mapExistingRecord.put(person.Person_1__c, new Set<Id>());
                }
                mapExistingRecord.get(person.Person_1__c).add(person.Person_2__c);

                if(!mapExistingRecord.containsKey(person.Person_2__c)){
                    mapExistingRecord.put(person.Person_1__c, new Set<Id>());
                }
                mapExistingRecord.get(person.Person_1__c).add(person.Person_1__c);           
            }

            for (People_Tracing__c trace : peopleTraces) {
                if(
                    (mapExistingRecord.containsKey(trace.Person_1__c) && mapExistingRecord.get(trace.Person_1__c).contains(trace.Person_2__c)) 
                    || 
                    (mapExistingRecord.containsKey(trace.Person_2__c) && mapExistingRecord.get(trace.Person_2__c).contains(trace.Person_1__c))
                ){
                    duplicates.add(trace);
                }
            }            
        }
        return duplicates;
    }

}
