void setBuildStatus(String url, String context, String message, String state, String backref){
  step([
    $class: "GitHubCommitStatusSetter",
    reposSource: [$class: "ManuallyEnteredRepositorySource", url: url ],
    contextSource: [$class: "ManuallyEnteredCommitContextSource", context: context ],
    errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
    statusBackrefSource: [ $class: "ManuallyEnteredBackrefSource", backref: backref ],
    statusResultSource: [ $class: "ConditionalStatusResultSource", results: [
        [$class: "AnyBuildResult", message: message, state: state]] ]
  ]);
}

String getRepoURL() {
  sh "git config --get remote.origin.url"
  sh "git config --get remote.origin.url > originurl"
  def originurl = readFile("originurl").trim()
  return originurl
}



def getItem(branchName) {
 Jenkins.instance.getItemByFullName("sonar-openedge/${branchName}")
}


def getTitle(json) {
   def slurper = new groovy.json.JsonSlurper()
   def jsonObject = slurper.parseText(json.content)
   jsonObject.title
}
void sendCommentToPullRequest(String prId, String messageContent){


     def SHA1 ="SHA1"
     script {
        SHA1 = sh(returnStdout: true, script: "git rev-parse HEAD").trim()
     }

     def message = """{"body": "$messageContent", "commit_id": "$SHA1", "path": "/", "position": 0}"""
     httpRequest authentication: 'sbuisson-git', httpMode: 'POST', requestBody: "${message}",  url: "https://api.github.com/repos/sbuisson/jenkinsCraft/issues/${prId}/comments"
}



node {
    stage('metrics') {
        checkout scm
        sh "mvn clean install -B"


        //sonar part
        def databaseSonarParam = " -Dsonar.jdbc.username=ci_user -Dsonar.jdbc.password=ci -Dsonar.jdbc.url=jdbc:postgresql://postgres:5432/ci "
        def sonarParam = " -Dsonar.host.url=http://sonarqube:9000 -Dsonar.login=admin -Dsonar.password=admin "
        def jenkinsJobUrl="http://localhost:8080/job/sbuisson/job/jenkinsCraft/view/change-requests/job/${env.BRANCH_NAME}"

        if ("master" == env.BRANCH_NAME) {
            echo "sonar master"
            sh "mvn sonar:sonar -Dsonar.analysis.mode=issues $sonarParam $databaseSonarParam  -B "
        } else if(!env.BRANCH_NAME.startsWith("PR-")){
            echo "sonar branch ${env.BRANCH_NAME}"
            sh "mvn sonar:sonar -Dsonar.analysis.mode=issues $sonarParam $databaseSonarParam  -B "
            sh "mvn sonar:sonar -Dsonar.analysis.mode=issues $sonarParam $databaseSonarParam  -B "
        } else {


            def messagePR=""
            def prId="${env.BRANCH_NAME.substring(3)}"



            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'sbuisson-git', usernameVariable: 'GH_LOGIN', passwordVariable: 'GH_PASSWORD']]) {
                withCredentials([[$class: 'StringBinding', credentialsId: ' git-token', variable: 'OATH']]) {
                    def githubSonarParam="-Dsonar.github.pullRequest=${prId}\
                                                        -Dsonar.github.repository=sbuisson/jenkinsCraft \
                                                        -Dsonar.github.login=${env.GH_LOGIN} -Dsonar.github.password=${env.GH_PASSWORD} \
                                                        -Dsonar.github.oauth=${env.OATH} "

                    echo "metrics sonar"
                    sh "mvn sonar:sonar -Dsonar.analysis.mode=preview $sonarParam $databaseSonarParam $githubSonarParam -B"
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'target/sonar', reportFiles: '*', reportName: 'sonar site', reportTitles: 'sonar'])
                    messagePR+="rapport sonar : <a href='http://localhost:9000/dashboard?id=fr.perso%3Ajenkinscraft'>here</a> and <a href='${jenkinsJobUrl}//sonar_site/index.html'>here</a> <br/>"

                    echo "metrics pitest"
                    sh "mvn pitest:mutationCoverage -DreportsDirectory=target/pit-reports -B"
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'target/pit-reports', reportFiles: '*', reportName: 'pitest site', reportTitles: 'pitest'])
                    messagePR+="rapport pitest : <a href='${jenkinsJobUrl}/HTML_site/pit-reports/index.html'>here</a> <br/>"

                    echo "metrics site"
                    sh "mvn site -B"
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'target/site', reportFiles: '*', reportName: 'HTML site', reportTitles: 'site'])
                    messagePR+="rapport site : <a href='${jenkinsJobUrl}//HTML_site/project-info.html'>here</a> <br/>"

                    messagePR+="job : ${env.JOB_NAME}"

                    sendCommentToPullRequest(prId, messagePR)
                }
            }
        }
    }

}
