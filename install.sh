#!/bin/bash

cd IdentitySdkCore && pod install && cd ..
cd IdentitySdkWebView && pod install && cd ..
cd IdentitySdkFacebook && pod install && cd ..
cd IdentitySdkGoogle && pod install && cd ..
cd IdentitySdkWeChat && pod install && cd ..
cd Sandbox && pod install && cd ..
