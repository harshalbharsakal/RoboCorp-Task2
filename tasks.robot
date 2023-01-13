*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}output
${RPA_SECRET_MANAGER}=              RPA.Robocorp.Vault.FileSecrets
${RPA_SECRET_FILE}=                 ${CURDIR}${/}vault.json


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csvfilename}=    Get the CSV name
    Download the CSV file    ${csvfilename}
    ${orders}=    Get orders
    ${URL}=    Get Order portal URL
    Open the robot order website    ${URL}
    Close the annoying modal
    Fill the Order Form    ${orders}
    Create ZIP package from PDF files
    [Teardown]    Close All Browsers


*** Keywords ***
Open the robot order website
    [Arguments]    ${URL}
    Open Available Browser    ${URL}

Get orders
    ${data}=    Read table from CSV    orders.csv    1
    RETURN    ${data}

Download the CSV file
    [Arguments]    ${csvfilename}
    Download    ${csvfilename}    overwrite=True

Close the annoying modal
    Click Element    xpath=//button[@type='button'][contains(.,'OK')]

Fill the Order Form
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Log Many    ${order}
        ${screenshot}=    Wait Until Keyword Succeeds
        ...    5x
        ...    1 sec
        ...    Fill and submit the form for one person
        ...    ${order}
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        #${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    order-another
        Close the annoying modal
    END

Fill and submit the form for one person
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath=//input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    ${screenshot_name}=    Take a screenshot of the robot    ${order}[Order number]
    Click Button    order
    Page Should Not Contain Element    xpath=//div[@class='alert alert-danger']
    RETURN    ${screenshot_name}

Store the receipt as a PDF file
    [Arguments]    ${ordernum}
    Wait Until Element Is Visible    id:order-completion
    ${order_results_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}Order_${ordernum}.pdf
    RETURN    ${OUTPUT_DIR}${/}Order_${ordernum}.pdf

Take a screenshot of the robot
    [Arguments]    ${ordernum}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}order_receipt_${ordernum}.png
    RETURN    ${OUTPUT_DIR}${/}order_receipt_${ordernum}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/../PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Get the CSV name
    Add text input    OrderFileName
    ...    label=FileName
    ...    placeholder=Please enter order file path

    ${result}=    Run dialog
    RETURN    ${result.OrderFileName}

Get Order portal URL
    ${url}=    Get Secret    URL
    RETURN    ${url}[websiteURL]
