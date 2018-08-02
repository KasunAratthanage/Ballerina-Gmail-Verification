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
    port: 9095
};

@http:ServiceConfig {
    basePath: "/"
}

service<http:Service> hello bind listener {


    //Get label and shows unread messages
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

    //List Messages
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/listemailmessages"
    }


    listEmailMessagesAndRead(endpoint caller, http:Request request)
    {
        http:Response response;
        //http:Response response;
        string messageId;
        string threadId;

        var response1 = gmailEP->listMessages(userId);
        match response1 {
            gmail:MessageListPage x => {

                any firstmessageid = x.messages[0].messageId;
                string stringVal = <string>firstmessageid;

                var response2 = gmailEP->readMessage(userId, untaint stringVal);
                match response2 {
                    gmail:Message m =>
                    {
                        any emailmsg = m.snippet;

                        string stringVal2 = <string>emailmsg;
                        response.setTextPayload(untaint stringVal2);
                        _ = caller->respond(response);
                    }
                    gmail:GmailError e => io:println(e);
                }
            }
            gmail:GmailError e => {
                io:println(e);
            }
        }
    }


}


