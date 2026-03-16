/**
 * @description Test class for CaseCreationService.
 */
@IsTest
private class CaseCreationServiceTest {
    @IsTest
    static void testCreateSupportCasesSuccess() {
        String statusValue = getPicklistValue(Case.Status, 'New');
        String originValue = getPicklistValue(Case.Origin, 'Web');
        String priorityValue = getPicklistValue(Case.Priority, 'Medium');

        CaseCreationService.CaseCreationRequest requestOne =
            new CaseCreationService.CaseCreationRequest();
        requestOne.customerName = 'Alicia Smith';
        requestOne.customerEmail = 'alicia.smith@example.com';
        requestOne.customerPhone = '4105551001';
        requestOne.subject = 'Unable to login';
        requestOne.casedescription = 'User cannot log in after password reset.';
        requestOne.status = statusValue;
        requestOne.origin = originValue;
        requestOne.priority = priorityValue;

        CaseCreationService.CaseCreationRequest requestTwo =
            new CaseCreationService.CaseCreationRequest();
        requestTwo.customerName = 'Marco Reed';
        requestTwo.customerEmail = 'marco.reed@example.com';
        requestTwo.subject = 'Billing question';
        requestTwo.casedescription = 'Customer sees duplicate charge.';
        requestTwo.status = statusValue;
        requestTwo.origin = originValue;
        requestTwo.priority = priorityValue;

        List<CaseCreationService.CaseCreationRequest> requests =
            new List<CaseCreationService.CaseCreationRequest>{ requestOne, requestTwo };

        Test.startTest();
        List<CaseCreationService.CaseCreationResponse> responses =
            CaseCreationService.createSupportCases(requests);
        Test.stopTest();

        Assert.areEqual(2, responses.size(), 'Two responses should be returned.');
        for (CaseCreationService.CaseCreationResponse response : responses) {
            Assert.areEqual(
                'SUCCESS',
                response.creationStatus,
                'Expected successful case creation.'
            );
            Assert.isTrue(
                String.isNotBlank(response.caseId),
                'Case Id should be populated.'
            );
            Assert.isTrue(
                String.isNotBlank(response.caseNumber),
                'Case Number should be populated.'
            );
            Assert.areEqual(
                null,
                response.errorMessage,
                'Error message should be empty on success.'
            );
        }

        List<Case> insertedCases = [
            SELECT Id, CaseNumber, Subject, SuppliedEmail, Origin, Priority
            FROM Case
            WHERE Id IN :new Set<Id>{
                (Id) responses[0].caseId,
                (Id) responses[1].caseId
            }
        ];
        Assert.areEqual(2, insertedCases.size(), 'Two cases should have been inserted.');
    }

    @IsTest
    static void testCreateSupportCasesMissingRequiredField() {
        String statusValue = getPicklistValue(Case.Status, 'New');
        String originValue = getPicklistValue(Case.Origin, 'Web');
        String priorityValue = getPicklistValue(Case.Priority, 'Medium');

        CaseCreationService.CaseCreationRequest invalidRequest =
            new CaseCreationService.CaseCreationRequest();
        invalidRequest.customerName = 'Taylor Green';
        invalidRequest.customerEmail = '';
        invalidRequest.subject = 'Cannot update profile';
        invalidRequest.casedescription = 'Profile save button does nothing.';
        invalidRequest.status = statusValue;
        invalidRequest.origin = originValue;
        invalidRequest.priority = priorityValue;

        Test.startTest();
        List<CaseCreationService.CaseCreationResponse> responses =
            CaseCreationService.createSupportCases(
                new List<CaseCreationService.CaseCreationRequest>{ invalidRequest }
            );
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response should be returned.');
        Assert.areEqual(
            'ERROR',
            responses[0].creationStatus,
            'Missing required values should return ERROR.'
        );
        Assert.areEqual(null, responses[0].caseId, 'Case should not be inserted.');
        Assert.areEqual(
            'Missing required value for customerEmail.',
            responses[0].errorMessage,
            'Expected a clear required-field message.'
        );
    }

    private static String getPicklistValue(
        Schema.SObjectField fieldToken,
        String preferredValue
    ) {
        Schema.DescribeFieldResult describe = fieldToken.getDescribe();
        for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == preferredValue) {
                return preferredValue;
            }
        }
        for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return preferredValue;
    }
}
