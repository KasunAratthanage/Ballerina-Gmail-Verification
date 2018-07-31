import ballerina/http;
import ballerina/config;
import ballerina/io;
import wso2/gmail;
import ballerina/log;

string accessToken = config:getAsString("ACCESS_TOKEN");
string clientId = config:getAsString("CLIENT_ID");
string clientSecret = config:getAsString("CLIENT_SECRET");
string refreshToken = config:getAsString("REFRESH_TOKEN");
string userId = config:getAsString("USER_ID");
string senderEmail = config:getAsString("SENDER");
string recipientEmail = config:getAsString("RECIPIENT");
string subject = config:getAsString("SUBJECT");
string messageBody = config:getAsString("MESSAGEBODY");
string contentType = config:getAsString("CONTENTTYPE");
string labelId = config:getAsString("LABELID");

endpoint gmail:Client gmailEP {

    clientConfig: {
        auth: {
            accessToken: accessToken,
            //"ya29.Glv-BTtBEFTrbAC6M2fe_oOWHuPFSR84HU6996MBUV56Mw_oB_DeQishuinHmsbj5Jk44v0cQmIm1NYtUCt55zyq_TJTgSCncQ42-YlolxWqB6HUIb0N8BZAAQfj",
            clientId: clientId,
            //"253723893500-bihee0nbk4rknss8t5fjq1qeclpsu6ba.apps.googleusercontent.com",
            clientSecret: clientSecret,
            //"jldzjGD672iWHxc_-B8nDWGH",
            refreshToken: refreshToken
            //"1/cyZnOOdEGluUEHZb7P4mz_65euzfH89lCJhKNikIppI"
        }
    }
};

endpoint http:Listener listener {
    port: 9090
};

@http:ServiceConfig {
    basePath: "/"
}

service<http:Service> hello bind listener {

    //Get label and verify the unread messages
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/getlabel"
    }

    getmaillabel(endpoint caller, http:Request request)
    {
        http:Response response1;

        //"Label_3394238941988420965";
        //string labelId= "INBOX";
        string messagesUnread;
        string id;
        string ownerType;
        int messagesTotal;
        int threadsTotal;
        int threadsUnread;
        string name;

        var response = gmailEP->getLabel(userId, labelId);
        match response {
            gmail:Label x => {

                string payload = " id: " + x.id + " \n " + "labelname: " + x.name + " \n " + "ownertype: " + x.ownerType
                    + " \n "
                    + "messagesTotal: " + x.messagesTotal + " \n " + "Unread Messages: " + x.messagesUnread + " \n " +
                    "threadsTotal: " + x.threadsTotal + " \n " + "threadsUnread: " + x.threadsUnread + " \n ";
                response1.statusCode = 200;
                response1.setTextPayload(untaint payload);
                _ = caller->respond(response1);
            }
            gmail:GmailError e => {
                response1.statusCode = 404;
                string payload = " Not Found";
                response1.setJsonPayload(payload);
                _ = caller->respond(response1);
            }
        }
    }

    //Create label
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/createlabel"
    }
    
    createmaillabel(endpoint caller, http:Request request)
    {
        http:Response response1;
        string messageListVisibility;
        // = "show";
        string labelShowIfUnread;
        //= "show";
        string labelListVisibility;
        //= "labelShow";
        string name;
        // = "Test1";

        var response = gmailEP->createLabel(userId, name, labelListVisibility, messageListVisibility);

        match response {
            string x => {

                string payload = "Label " + name + " created ";
                response1.setJsonPayload(payload);
                _ = caller->respond(response1);
            }
            gmail:GmailError e => {

                string payload = "Invalid value for parameters :  is not a valid values";
                response1.setJsonPayload(payload);
                _ = caller->respond(response1);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/readmessage"
        }

    readEmailMessage(endpoint caller, http:Request request) {
        http:Request newRequest = new;
        //Check whether 'sleeptime' header exisits in the invoking request
        if (!request.hasHeader("messageid")) {
            http:Response errorResponse = new;
            //If not included 'sleeptime' in header print this as a error message
            errorResponse.statusCode = 500;
            json errMsg = { "error": "'messageid' header is not found" };
            errorResponse.setPayload(errMsg);
            caller->respond(errorResponse) but {
                error e => log:printError("Error sending response", err = e)
            };
            done;
        }

        string nameString = request.getHeader("messageid");
        string messageId = nameString;

        var response = gmailEP->readMessage(userId, untaint messageId);
        match response {
            gmail:Message m => io:println("Received Message: ", m);
            gmail:GmailError e => io:println(e);
        }
    }

    //List Messages
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/listemailmessages"
    }

    listEmailMessages(endpoint caller, http:Request request)
    {
        http:Response response1;
        string messageId;
        string threadId;
        
        var response = gmailEP->listMessages(userId);
        match response {
            gmail:MessageListPage x => {
                io:println("Message: ", x);
            }

            gmail:GmailError e => {
                io:println(e);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/userprofile"
    }

    viewUserEmailProfile(endpoint caller, http:Request request) {

        var response3 = gmailEP->getUserProfile(userId);        
        match response3 {
            gmail:UserProfile x => {
                io:println("Message: ", x);
            }
            gmail:GmailError e => {
                io:println(e);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/listthread"
    }

    readt(endpoint caller, http:Request request)
    {
        var response3 = gmailEP->listThreads(userId);
        match response3 {
            gmail:ThreadListPage x =>
            io:println("Message: ", x);
            gmail:GmailError e => io:println(e);
        }
    }
}


