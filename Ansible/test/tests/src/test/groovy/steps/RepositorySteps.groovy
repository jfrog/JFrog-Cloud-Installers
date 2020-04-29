package steps


import static io.restassured.RestAssured.given

class RepositorySteps {

    def getHealthCheckResponse(artifactoryURL) {
        return given()
                .when()
                .get("http://" + artifactoryURL + "/router/api/v1/system/health")
                .then()
                .extract().response()
    }

    def ping() {
        return given()
                .when()
                .get("/api/system/ping")
                .then()
                .extract().response()
    }

    def createRepositories(File body, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/yaml")
                .body(body)
                .when()
                .patch("/api/system/configuration")
                .then()
                .extract().response()
    }
    // https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-GetRepositories
    def getRepos() {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/yaml")
                .when()
                .get("/api/repositories")
                .then()
                .extract().response()

    }
    // https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-DeleteRepository
    def deleteRepository(repoName, username, password) {
        return given()
                .auth()
                .preemptive()
                .basic("${username}", "${password}")
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/yaml")
                .when()
                .delete("/api/repositories/" + repoName)
                .then()
                .extract().response()

    }

    def createDirectory(repoName, directoryName) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("content-Type", "application/yaml")
                .when()
                .put("/" + repoName + "/" + directoryName)
                .then()
                .extract().response()

    }

    def deployArtifact(repoName, directoryName, artifact, filename) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .body(artifact)
                .when()
                .put("/" + repoName + "/" + directoryName + "/" + filename)
                .then()
                .extract().response()

    }

    def deleteItem(repoName, directoryName, artifact, filename) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .body(artifact)
                .when()
                .delete("/" + repoName + "/" + directoryName + "/" + filename)
                .then()
                .extract().response()

    }

    def getInfo(repoName, directoryName, artifact, filename) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .body(artifact)
                .when()
                .get("/api/storage/" + repoName + "/" + directoryName + "/" + filename)
                .then()
                .extract().response()

    }

    def createSupportBundle(name, startDate, endDate) {
        return given()
                .header("Cache-Control", "no-cache")
                .header("Content-Type", "application/json")
                .body("{ \n" +
                        "   \"name\":\"${name}\",\n" +
                        "   \"description\":\"desc\",\n" +
                        "   \"parameters\":{ \n" +
                        "      \"configuration\": \"true\",\n" +
                        "      \"system\": \"true\",             \n" +
                        "      \"logs\":{ \n" +
                        "         \"include\": \"true\",          \n" +
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
                .post("/api/system/support/bundle")
                .then()
                .extract().response()

    }


}