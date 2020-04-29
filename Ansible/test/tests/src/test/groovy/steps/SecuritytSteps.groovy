package steps

import org.testng.annotations.DataProvider

import static io.restassured.RestAssured.given


class SecuritytSteps {

    def createUser(usernameRt, emailRt, passwordRt) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        "  \"email\" : \"${emailRt}\",\n" +
                        "  \"password\": \"${passwordRt}\"\n" +
                        "}")
                .when()
                .put("/api/security/users/${usernameRt}")
                .then()
                .extract().response()
    }

    def getUserDetails(usernameRt) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/api/security/users/${usernameRt}")
                .then()
                .extract().response()
    }

    def deleteUser(usernameRt) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .delete("/api/security/users/${usernameRt}")
                .then()
                .extract().response()
    }

    def generateAPIKey(usernameRt, passwordRt) {
        return given()
                .auth()
                .preemptive()
                .basic("${usernameRt}", "${passwordRt}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .post("/api/security/apiKey")
                .then()
                .extract().response()
    }

    def getAPIKey(usernameRt, passwordRt) {
        return given()
                .auth()
                .preemptive()
                .basic("${usernameRt}", "${passwordRt}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/api/security/apiKey")
                .then()
                .extract().response()
    }

    def regenerateAPIKey(usernameRt, passwordRt) {
        return given()
                .auth()
                .preemptive()
                .basic("${usernameRt}", "${passwordRt}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .put("/api/security/apiKey")
                .then()
                .extract().response()
    }

    def createGroup(groupName) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\"name\": \"${groupName}\"}")
                .when()
                .put("/api/security/groups/${groupName}")
                .then()
                .extract().response()
    }

    def getGroup(groupName) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\"name\": \"${groupName}\"}")
                .when()
                .get("/api/security/groups/${groupName}")
                .then()
                .extract().response()
    }

    def deleteGroup(groupName) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .delete("/api/security/groups/${groupName}")
                .then()
                .extract().response()
    }

    def createPermissions(permissionName, repository, user1, user2,
                          group1, group2, action1, action2, action3) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .body("{\n" +
                        " \"name\": \"${permissionName}\",\n" +
                        "   \"repo\": {\n" +
                        "      \"repositories\": [ \"${repository}\" ],\n" +
                        "      \"actions\": {\n" +
                        "          \"users\" : {\n" +
                        "            \"${user1}\": [ \"${action1}\",\"${action2}\",\"${action3}\" ], \n" +
                        "            \"${user2}\" : [ \"${action1}\",\"${action2}\",\"${action3}\" ]\n" +
                        "          },\n" +
                        "          \"groups\" : {\n" +
                        "            \"${group1}\" : [ \"${action1}\",\"${action2}\",\"${action3}\" ],\n" +
                        "            \"${group2}\" : [ \"${action1}\",\"${action2}\" ]\n" +
                        "          }\n" +
                        "    }\n" +
                        "  }\n" +
                        "}")
                .when()
                .put("/api/v2/security/permissions/testPermission")
                .then()
                .extract().response()
    }

    def getPermissions( permissionName) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .get("/api/v2/security/permissions/${permissionName}")
                .then()
                .extract().response()
    }

    def deletePermissions(permissionName) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/json")
                .when()
                .delete("/api/v2/security/permissions/${permissionName}")
                .then()
                .extract().response()
    }


    // Data providers

    @DataProvider(name="users")
    public Object[][] users() {
        return new Object[][]{
                ["testuser0", "email0@jfrog.com", "password123"],
                ["testuser1", "email1@jfrog.com", "password123"],
                ["testuser2", "email2@jfrog.com", "password123"],
                ["testuser3", "email3@jfrog.com", "password123"],
                ["testuser4", "email4@jfrog.com", "password123"],
                ["testuser5", "email5@jfrog.com", "password123"],
                ["testuser6", "email6@jfrog.com", "password123"],
                ["testuser7", "email7@jfrog.com", "password123"],
                ["testuser8", "email8@jfrog.com", "password123"],
                ["testuser9", "email9@jfrog.com", "password123"]
        }
    }

    @DataProvider(name="groups")
    public Object[][] groups() {
        return new Object[][]{
                ["test-group-0"],
                ["test-group-1"],
                ["test-group-2"],
                ["test-group-3"],
                ["test-group-4"],
                ["test-group-5"],
                ["test-group-6"],
                ["test-group-7"],
                ["test-group-8"],
                ["test-group-9"]
        }
    }
}
