package steps

import org.testng.annotations.DataProvider

import static io.restassured.RestAssured.given

class XraySteps {

    def createIssueEvent(issueID, cve, summary, description, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "    \"id\": \"${issueID}\",\n" +
                        "    \"type\": \"Security\",\n" +
                        "    \"provider\": \"JFrog\",\n" +
                        "    \"package_type\": \"maven\",\n" +
                        "    \"severity\": \"High\",\n" +
                        "    \"components\": [\n" +
                        "        {\n" +
                        "            \"id\": \"aero:aero\",\n" +
                        "            \"vulnerable_versions\": [\n" +
                        "                \"[0.2.3]\"\n" +
                        "            ]\n" +
                        "        }\n" +
                        "    ],\n" +
                        "    \"cves\": [\n" +
                        "        {\n" +
                        "            \"cve\": \"${cve}\",\n" +
                        "            \"cvss_v2\": \"2.4\"\n" +
                        "        }\n" +
                        "    ],\n" +
                        "    \"summary\": \"${summary}\",\n" +
                        "    \"description\": \"${description}\",\n" +
                        "    \"sources\": [\n" +
                        "        {\n" +
                        "            \"source_id\": \"${cve}\"\n" +
                        "        }\n" +
                        "    ]\n" +
                        "}")
                .when()
                .post("/v1/events")
                .then()
                .extract().response()
    }

    def updateIssueEvent(issueID, cve, summary, description, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "    \"type\": \"Security\",\n" +
                        "    \"provider\": \"JFrog\",\n" +
                        "    \"package_type\": \"maven\",\n" +
                        "    \"severity\": \"High\",\n" +
                        "    \"components\": [\n" +
                        "        {\n" +
                        "            \"id\": \"aero:aero\",\n" +
                        "            \"vulnerable_versions\": [\n" +
                        "                \"[0.2.3]\"\n" +
                        "            ]\n" +
                        "        }\n" +
                        "    ],\n" +
                        "    \"cves\": [\n" +
                        "        {\n" +
                        "            \"cve\": \"${cve}\",\n" +
                        "            \"cvss_v2\": \"2.4\"\n" +
                        "        }\n" +
                        "    ],\n" +
                        "    \"summary\": \"${summary}\",\n" +
                        "    \"description\": \"${description}\",\n" +
                        "    \"sources\": [\n" +
                        "        {\n" +
                        "            \"source_id\": \"${cve}\"\n" +
                        "        }\n" +
                        "    ]\n" +
                        "}")
                .when()
                .put("/v1/events/${issueID}")
                .then()
                .extract().response()
    }

    def createPolicy(policyName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "  \"name\": \"${policyName}\",\n" +
                        "  \"type\": \"security\",\n" +
                        "  \"description\": \"some description\",\n" +
                        "  \"rules\": [\n" +
                        "    {\n" +
                        "      \"name\": \"securityRule\",\n" +
                        "      \"priority\": 1,\n" +
                        "      \"criteria\": {\n" +
                        "        \"min_severity\": \"High\"\n" +
                        "      },\n" +
                        "      \"actions\": {\n" +
                        "        \"mails\": [\n" +
                        "          \"mail1@example.com\",\n" +
                        "          \"mail2@example.com\"\n" +
                        "        ],\n" +
                        "        \"fail_build\": true,\n" +
                        "        \"block_download\": {\n" +
                        "          \"unscanned\": true,\n" +
                        "          \"active\": true\n" +
                        "        }\n" +
                        "      }\n" +
                        "    }\n" +
                        "  ]\n" +
                        "}")
                .when()
                .post("/v1/policies")
                .then()
                .extract().response()
    }

    def updatePolicy(policyName, description, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "  \"name\": \"${policyName}\",\n" +
                        "  \"type\": \"security\",\n" +
                        "  \"description\": \"${description}\",\n" +
                        "  \"rules\": [\n" +
                        "    {\n" +
                        "      \"name\": \"securityRule\",\n" +
                        "      \"priority\": 1,\n" +
                        "      \"criteria\": {\n" +
                        "        \"min_severity\": \"High\"\n" +
                        "      },\n" +
                        "      \"actions\": {\n" +
                        "        \"mails\": [\n" +
                        "          \"mail1@example.com\",\n" +
                        "          \"mail2@example.com\"\n" +
                        "        ],\n" +
                        "        \"fail_build\": true,\n" +
                        "        \"block_download\": {\n" +
                        "          \"unscanned\": true,\n" +
                        "          \"active\": true\n" +
                        "        }\n" +
                        "      }\n" +
                        "    }\n" +
                        "  ]\n" +
                        "}")
                .when()
                .put("/v1/policies/${policyName}")
                .then()
                .extract().response()
    }

    def getPolicy(policyName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/policies/${policyName}")
                .then()
                .extract().response()
    }

    def getPolicies(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/policies")
                .then()
                .extract().response()
    }

    def deletePolicy(policyName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .delete("/v1/policies/${policyName}")
                .then()
                .extract().response()
    }

    def getIssueEvent(issueID, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/events/${issueID}")
                .then()
                .extract().response()
    }

    def createWatchEvent(watchName, policyName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "    \"general_data\": {\n" +
                        "        \"name\": \"${watchName}\",\n" +
                        "        \"description\": \"This is a new watch created using API V2\",\n" +
                        "        \"active\": true\n" +
                        "    },\n" +
                        "    \"project_resources\": {\n" +
                        "        \"resources\": [\n" +
                        "            {\n" +
                        "                \"type\": \"all-repos\",\n" +
                        "                \"filters\": [\n" +
                        "                    {\n" +
                        "                        \"type\": \"package-type\",\n" +
                        "                        \"value\": \"Docker\"\n" +
                        "                    },\n" +
                        "                    {\n" +
                        "                        \"type\": \"package-type\",\n" +
                        "                        \"value\": \"Debian\"\n" +
                        "                    }\n" +
                        "                ]\n" +
                        "            }\n" +
                        "        ]\n" +
                        "    },\n" +
                        "    \"assigned_policies\": [\n" +
                        "        {\n" +
                        "            \"name\": \"${policyName}\",\n" +
                        "            \"type\": \"security\"\n" +
                        "        }\n" +
                        "    ]\n" +
                        "}")
                .when()
                .post("/v2/watches")
                .then()
                .extract().response()
    }

    def updateWatchEvent(watchName, description, policyName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "    \"general_data\": {\n" +
                        "        \"name\": \"${watchName}\",\n" +
                        "        \"description\": \"${description}\",\n" +
                        "        \"active\": true\n" +
                        "    },\n" +
                        "    \"project_resources\": {\n" +
                        "        \"resources\": [\n" +
                        "            {\n" +
                        "                \"type\": \"all-repos\",\n" +
                        "                \"filters\": [\n" +
                        "                    {\n" +
                        "                        \"type\": \"package-type\",\n" +
                        "                        \"value\": \"Docker\"\n" +
                        "                    },\n" +
                        "                    {\n" +
                        "                        \"type\": \"package-type\",\n" +
                        "                        \"value\": \"Debian\"\n" +
                        "                    }\n" +
                        "                ]\n" +
                        "            }\n" +
                        "        ]\n" +
                        "    },\n" +
                        "    \"assigned_policies\": [\n" +
                        "        {\n" +
                        "            \"name\": \"${policyName}\",\n" +
                        "            \"type\": \"security\"\n" +
                        "        }\n" +
                        "    ]\n" +
                        "}")
                .when()
                .put("/v2/watches/${watchName}")
                .then()
                .extract().response()
    }

    def getWatchEvent(watchName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v2/watches/${watchName}")
                .then()
                .extract().response()
    }

    def deleteWatchEvent(watchName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .delete("/v2/watches/${watchName}")
                .then()
                .extract().response()
    }

    def assignPolicy(watchName, policyName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "    \"watches\": [\n" +
                        "        \"${watchName}\"\n" +
                        "    ]\n" +
                        "}")
                .when()
                .post("/v1/policies/${policyName}/assign")
                .then()
                .extract().response()
    }

    def getIntegrationConfiguration(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/integration")
                .then()
                .extract().response()
    }

    def addtIntegrationConfiguration(username, password, vendorName) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "  \"vendor\": \"${vendorName}\",\n" +
                        "  \"api_key\": \"12345\",\n" +
                        "  \"enabled\": true,\n" +
                        "  \"context\": \"project_id\",\n" +
                        "  \"url\": \"https://saas.whitesourcesoftware.com/xray\",\n" +
                        "  \"description\": \"WhiteSource provides a simple yet powerful open source security and licenses management solution. More details at http://www.whitesourcesoftware.com.\",\n" +
                        "  \"test_url\": \"https://saas.whitesourcesoftware.com/xray/api/checkauth\"\n" +
                        "}")
                .when()
                .post("/v1/integration")
                .then()
                .extract().response()
    }

    def postSystemParameters(username, password, body) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body(body)
                .when()
                .put("/v1/configuration/systemParameters")
                .then()
                .extract().response()
    }

    def getSystemParameters(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/configuration/systemParameters")
                .then()
                .extract().response()
    }

    def getBinaryManager(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/binMgr/default")
                .then()
                .extract().response()
    }


    def getIndexingConfiguration(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/v1/binMgr/default/repos")
                .then()
                .extract().response()
    }

    def updateIndexingConfiguration(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "    \"indexed_repos\": [\n" +
                        "        {\n" +
                        "            \"name\": \"docker-local\",\n" +
                        "            \"type\": \"local\",\n" +
                        "            \"pkg_type\": \"Docker\"\n" +
                        "        },\n" +
                        "        {\n" +
                        "            \"name\": \"generic-dev-local\",\n" +
                        "            \"type\": \"local\",\n" +
                        "            \"pkg_type\": \"Generic\"\n" +
                        "        }\n" +
                        "    ],\n" +
                        "    \"non_indexed_repos\": []\n" +
                        "}")
                .when()
                .put("/v1/binMgr/default/repos")
                .then()
                .extract().response()
    }



    def startScan(username, password, componentID) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .body("{\n" +
                        " \"componentID\": \"${componentID}\"\n" +
                        "}")
                .when()
                .post("/v1/scanArtifact")
                .then()
                .extract().response()
    }


    def artifactSummary(username, password, artifactPath) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "  \"checksums\": [\n" +
                        "    \"\"\n" +
                        "  ],\n" +
                        "  \"paths\": [\n" +
                        "    \"${artifactPath}\"\n" +
                        "  ]\n" +
                        "}")
                .when()
                .post("/v1/summary/artifact")
                .then()
                .extract().response()
    }

    def createSupportBundle(username, password, name, startDate, endDate) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .body("{ \n" +
                        "   \"name\":\"${name}\",\n" +
                        "   \"description\":\"desc\",\n" +
                        "   \"parameters\":{ \n" +
                        "      \"configuration\": true,\n" +
                        "      \"system\": true,             \n" +
                        "      \"logs\":{ \n" +
                        "         \"include\": true,          \n" +
                            "         \"start_date\":\"${startDate}\",\n" +
                        "         \"end_date\":\"${endDate}\"\n" +
                        "      },\n" +
                        "      \"thread_dump\":{ \n" +
                        "         \"count\": 1,\n" +
                        "         \"interval\": 0\n" +
                        "      }\n" +
                        "   }\n" +
                        "}")
                .when()
                .post("/v1/system/support/bundle")
                .then()
                .extract().response()

    }

    def getSystemMonitoringStatus(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .when()
                .get("/v1/monitor")
                .then()
                .extract().response()
    }

    def xrayPingRequest(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .when()
                .get("/v1/system/ping")
                .then()
                .extract().response()
    }

    def xrayGetVersion(username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .when()
                .get("/v1/system/version")
                .then()
                .extract().response()
    }

    // Data providers

    @DataProvider(name = "issueEvents")
    public Object[][] issueEvents() {
        return new Object[][]{
                ["XRAY-", "CVE-2017-2000386", "A very important custom issue", "A very important custom issue"]

        }
    }

}