public with sharing class CTPersonController {    
    public static String getToken(String mobileNo){
        Blob value = Blob.valueOf(mobileNo);
        Blob hash = Crypto.generateDigest('MD5', value);

        // Get the string value of hash blob        
        return EncodingUtil.base64Encode(hash);
    }

    public static List<Person__c> getRecentHealthChanges(){
        List<Person__c> ListaP = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c FROM Person__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
        return ListaP;
    }
    public static List<Person__c> searchPeople(String searchItem){
        searchItem = searchItem + '%';
        List<Person__c> ListaP = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
            FROM Person__c 
            WHERE Name LIKE :searchItem 
                OR Mobile__c LIKE:searchItem 
                OR Token__c LIKE:searchItem
            ORDER BY Status_Update_Date__c DESC NULLS LAST];
        return ListaP;

    }    
    public static Person__c getPersonById(String personId){
        List<Person__c> Persona = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                                   FROM Person__c 
                                   WHERE Id =:personId];
        if(Persona != null && Persona.size() > 0){
            return Persona[0];
        }
        return null;
    }
    public static Map<String, Integer> getHealthStatusCount(){
        Map<String, Integer> statusCount = new Map<String, Integer>();
        for (AggregateResult result: [SELECT Health_Status__c, COUNT(Id) PersonCount FROM Person__c GROUP BY Health_Status__c]) {
            String healthStatus = String.valueOf(result.get('Health_Status__c'));
            Integer cont = Integer.valueOf(result.get('PersonCount'));
            statusCount.put(healthStatus,cont);
            
        }
        return statusCount;
    }

    public static Set<Id> getCohabitants(Set<Id> personIds){
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                    FROM People_Tracing__c 
                                                    WHERE (Person_1__c IN: personIds OR Person_2__c IN: personIds) 
                                                        AND Contact_Type__c = 'Cohabitant'
                                                        AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)];
        Set<Id> cohabitants = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!personIds.contains(pt.Person_1__c)){
                cohabitants.add(pt.Person_1__c);
            }
            if(!personIds.contains(pt.Person_2__c)){
                cohabitants.add(pt.Person_2__c);
            }
        }
        return cohabitants;
    }

    public static Set<Id> getNeighbours(Set<Id> personIds){        
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                    FROM People_Tracing__c 
                                                    WHERE (Person_1__c IN: personIds OR Person_2__c IN: personIds) 
                                                        AND Contact_Type__c = 'Neighbour'
                                                        AND (Person_1__r.Health_Status__c = 'Green' OR  Person_2__r.Health_Status__c = 'Green')];
        Set<Id> neighbours = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!personIds.contains(pt.Person_1__c)){
                neighbours.add(pt.Person_1__c);
            }
            if(!personIds.contains(pt.Person_2__c)){
                neighbours.add(pt.Person_2__c);
            }
        }
        return neighbours;
    }

    public static Set<Id> getPrimaryContacts(Set<Id> personIds){        
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                    FROM People_Tracing__c 
                                                    WHERE (Person_1__c IN: personIds OR Person_2__c IN: personIds) 
                                                        AND Contact_Type__c = 'Other'
                                                        AND Contact_Date__c = LAST_N_DAYS:10
                                                        AND (Person_1__r.Health_Status__c IN :healthStatuses OR  Person_2__r.Health_Status__c IN :healthStatuses)];
        Set<Id> primaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!personIds.contains(pt.Person_1__c)){
                primaryContacts.add(pt.Person_1__c);
            }
            if(!personIds.contains(pt.Person_2__c)){
                primaryContacts.add(pt.Person_2__c);
            }
        }
        return primaryContacts;
    }

    public static Set<Id> getSecondaryContacts(Set<Id> primaryContactsIds){        
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                    FROM People_Tracing__c 
                                                    WHERE (Person_1__c IN: primaryContactsIds OR Person_2__c IN: primaryContactsIds) 
                                                        AND Contact_Type__c = 'Other'
                                                        AND Contact_Date__c = LAST_N_DAYS:10
                                                        AND (Person_1__r.Health_Status__c = 'Green' OR  Person_2__r.Health_Status__c = 'Green')];
        Set<Id> secondaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!primaryContactsIds.contains(pt.Person_1__c)){
                secondaryContacts.add(pt.Person_1__c);
            }
            if(!primaryContactsIds.contains(pt.Person_2__c)){
                secondaryContacts.add(pt.Person_2__c);
            }
        }
        return secondaryContacts;
    }    

    
}