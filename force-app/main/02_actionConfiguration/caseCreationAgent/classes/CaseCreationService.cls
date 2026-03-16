/**
 * @description Invocable service that creates Case records with required details.
 */
public with sharing class CaseCreationService {
    public class CaseCreationRequest {
        @InvocableVariable(
            label='Subject'
            description='Short summary of the issue'
            required=true
        )
        public String subject;

        @InvocableVariable(
            label='Case Description'
            description='Detailed issue description'
            required=true
        )
        public String casedescription;

        @InvocableVariable(
            label='Status'
            description='Case status (for example: New, Working, Closed)'
            required=true
        )
        public String status;

        @InvocableVariable(
            label='Origin'
            description='Case origin (for example: Web, Phone, Email)'
            required=true
        )
        public String origin;

        @InvocableVariable(
            label='Priority'
            description='Case priority (for example: Low, Medium, High)'
            required=true
        )
        public String priority;

        @InvocableVariable(
            label='Customer Name'
            description='Name supplied by the customer'
            required=true
        )
        public String customerName;

        @InvocableVariable(
            label='Customer Email'
            description='Email supplied by the customer'
            required=true
        )
        public String customerEmail;

        @InvocableVariable(
            label='Customer Phone'
            description='Phone supplied by the customer'
            required=false
        )
        public String customerPhone;
    }

    public class CaseCreationResponse {
        @InvocableVariable(
            label='Case Id'
            description='Id of the newly created case'
        )
        public String caseId;

        @InvocableVariable(
            label='Case Number'
            description='Auto-generated case number'
        )
        public String caseNumber;

        @InvocableVariable(
            label='Creation Status'
            description='SUCCESS or ERROR'
        )
        public String creationStatus;

        @InvocableVariable(
            label='Error Message'
            description='Details when creation fails'
        )
        public String errorMessage;
    }

    @InvocableMethod(
        label='Create Support Case'
        description='Creates Salesforce Case records from required support details'
    )
    public static List<CaseCreationResponse> createSupportCases(
        List<CaseCreationRequest> requests
    ) {
        List<CaseCreationResponse> responses = new List<CaseCreationResponse>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        List<Case> casesToInsert = new List<Case>();
        List<Integer> requestIndexes = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            CaseCreationRequest request = requests[i];
            CaseCreationResponse response = new CaseCreationResponse();

            String missingField = getFirstMissingRequiredField(request);
            if (missingField != null) {
                response.creationStatus = 'ERROR';
                response.errorMessage =
                    'Missing required value for ' + missingField + '.';
                responses.add(response);
                continue;
            }

            Case newCase = new Case();
            newCase.Subject = request.subject.trim();
            newCase.Description = request.casedescription.trim();
            newCase.Status = request.status.trim();
            newCase.Origin = request.origin.trim();
            newCase.Priority = request.priority.trim();
            newCase.SuppliedName = request.customerName.trim();
            newCase.SuppliedEmail = request.customerEmail.trim();
            if (!String.isBlank(request.customerPhone)) {
                newCase.SuppliedPhone = request.customerPhone.trim();
            }

            casesToInsert.add(newCase);
            requestIndexes.add(i);
            responses.add(response);
        }

        if (casesToInsert.isEmpty()) {
            return responses;
        }

        Database.SaveResult[] saveResults = Database.insert(casesToInsert, false);

        for (Integer resultIndex = 0; resultIndex < saveResults.size(); resultIndex++) {
            Database.SaveResult saveResult = saveResults[resultIndex];
            Integer responseIndex = requestIndexes[resultIndex];
            CaseCreationResponse response = responses[responseIndex];

            if (saveResult.isSuccess()) {
                Case insertedCase = casesToInsert[resultIndex];
                response.caseId = insertedCase.Id;
                response.caseNumber = insertedCase.CaseNumber;
                response.creationStatus = 'SUCCESS';
            } else {
                response.creationStatus = 'ERROR';
                response.errorMessage = saveResult.getErrors()[0].getMessage();
            }
        }

        return responses;
    }

    private static String getFirstMissingRequiredField(CaseCreationRequest request) {
        if (request == null) {
            return 'request';
        }
        if (String.isBlank(request.customerName)) {
            return 'customerName';
        }
        if (String.isBlank(request.customerEmail)) {
            return 'customerEmail';
        }
        if (String.isBlank(request.subject)) {
            return 'subject';
        }
        if (String.isBlank(request.casedescription)) {
            return 'casedescription';
        }
        if (String.isBlank(request.status)) {
            return 'status';
        }
        if (String.isBlank(request.origin)) {
            return 'origin';
        }
        if (String.isBlank(request.priority)) {
            return 'priority';
        }
        return null;
    }
}
