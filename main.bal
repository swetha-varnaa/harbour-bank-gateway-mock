// Harbour Bank gateway mock: registry, screening, notify.
// Same contract as build/stub/gateway_stub.py and the spec section 3.
import ballerina/http;

service / on new http:Listener(9090) {

    // GET /registry/v1/companies/{crNumber}
    resource function get registry/v1/companies/[string crNumber]() returns json|http:NotFound|http:ServiceUnavailable {
        if crNumber.startsWith("0404") {
            return <http:NotFound>{body: {"error": "CR not found"}};
        }
        if crNumber.startsWith("503") {
            return <http:ServiceUnavailable>{body: {"error": "registry unavailable"}};
        }
        return {
            "crNumber": crNumber,
            "companyName": crNumber == "1010203040" ? "Falcon Trading LLC" : "Demo Company " + crNumber.substring(6),
            "legalForm": "LLC",
            "status": "ACTIVE",
            "expiryDate": "2027-03-31",
            "address": "Unit 4, Harbour Road, Demo City",
            "registryRef": "REG-" + crNumber.substring(5)
        };
    }

    // POST /screening/v1/checks  (answers straight away: no callback in the simple scope)
    resource function post screening/v1/checks(@http:Payload json body) returns http:Accepted|http:ServiceUnavailable|error {
        json subject = check body.subject;
        string cr = check subject.crNumber;
        if cr.startsWith("503") {
            return <http:ServiceUnavailable>{body: {"error": "screening provider unavailable"}};
        }
        boolean hit = cr.startsWith("7");
        return <http:Accepted>{body: {
            "checkId": "CHK-" + cr,
            "status": "COMPLETED",
            "result": hit ? "HIT" : "CLEAR",
            "score": hit ? 71 : 12
        }};
    }

    // POST /notify/v1/sms and /notify/v1/email
    resource function post notify/v1/[string channel](@http:Payload json body) returns http:Accepted {
        return <http:Accepted>{body: {"messageId": channel.toUpperAscii() + "-99120", "status": "QUEUED"}};
    }
}