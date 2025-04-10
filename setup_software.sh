#!/bin/bash
apt remove thunderbird
apt install -y evolution evolution-ews

# Configure Evolution to use Microsoft Exchange as follows:
# Open Evolution and go to Edit -> Preferences -> Mail Accounts -> Add
# Press Next, enter your name and email address
# Uncheck "Look up mail server details", click Next
# Select "Exchange Web Services" from Server Type
# Enter https://outlook.office365.com/EWS/Exchange.asmx for Host URL
# Select OAuth2 as Authentication Method
# Next -> Next -> Next -> Apply
