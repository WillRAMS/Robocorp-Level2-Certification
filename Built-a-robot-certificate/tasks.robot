*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the Pics of the ordered robot.
...               Embeds the Pics of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Dialogs
Library           RPA.FileSystem
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${OUTPUT_DIR}${/}temp

*** Comments ***
The following 2 variables are not longer needed.
${URL_Web}=       https://robotsparebinindustries.com/#/robot-order
${URL_Web_Download}=    https://robotsparebinindustries.com/orders.csv
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up directories
    ${url_needed}    Collect URL From User
    Get URL value and Open the intranet websited
    Download CSV File From Web    ${url_needed}
    Fill the form using the data from the CSV file
    Create ZIP package from PDF Order files
    Cleanup temporary PDF directory
    [Teardown]    Press OK and close the browser

*** Keywords ***
Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}

Collect URL From User
    Add text input    url    label=Welcome to our RPA World at RAMS!    placeholder=Please paste your Orders CSV URL Link Here...
    Add text    then hit the Submit button to run this puppy!
    ${response}=    Run dialog    on_top=True    title=Hi User ~[O_O]~
    [Return]    ${response.url}

Get URL value and Open the intranet websited
    ${secret}=    Get Secret    weburl
    Open Available Browser    ${secret}[url]

Download CSV File From Web
    [Arguments]    ${url_needed}
    Download    ${url_needed}    overwrite=True

Fill the form using the data from the CSV file
    ${Bot_Orders}=    Read table from CSV    orders.CSV    header=True
    FOR    ${row}    IN    @{Bot_Orders}
        Web Set up
        Fill and Submit the Form for each Order    ${row}
        Preview the order
        Wait For Receipt
        Store the receipt as a PDF file    ${row}
        Take a Pic of the robot image    ${row}
        Embed the robot Pic to the receipt PDF file    ${row}
        Order Another Robot
    END

Web Set up
    Click Button    OK
    Wait Until Page Contains Element    id:head

Fill and Submit the Form for each Order
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the order
    Click Button    Preview

Wait For Receipt
    Wait Until Keyword Succeeds    3x    0.5s    Submit the order
    Wait Until Page Contains Element    id:receipt

Submit the order
    Click Button    Order
    ${element}=    Does Page Contain Element    receipt
    IF    '${element}' == 'False'
        Submit the order
    END

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Process#${row}[Order number].pdf

Take a Pic of the robot image
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Image#${row}[Order number].png

Embed the robot Pic to the receipt PDF file
    [Arguments]    ${row}
    Open Pdf    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Process#${row}[Order number].pdf
    ${files}=    Create List
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Process#${row}[Order number].pdf
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Image#${row}[Order number].png:align=center
    Add Files To PDF    ${files}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Process#${row}[Order number].pdf
    Close Pdf
    Remove File    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Order_Image#${row}[Order number].png

Order Another Robot
    Click Button    order-another

Create ZIP package from PDF Order files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}Orders_PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True
    Success Message

Success Message
    Add icon    Success
    Add heading    Your Bot orders have been processed!
    Run dialog    title=Hi User ~[O_O]~ Congratulations

Press OK and close the browser
    Web Set up
    Close Browser
