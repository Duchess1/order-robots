*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Robocorp.Vault
Library           RPA.Tables
Library           OperatingSystem
Library           RPA.Archive
Library           RPA.Dialogs

*** Variables ***
${orders_file}    ${CURDIR}${/}orders.csv
${pdf_folder}     ${CURDIR}${/}PDFs/
${screenshot_folder}    ${CURDIR}${/}Screenshots/
${zip_file}       ${CURDIR}${/}output/receipts.zip

*** Keywords ***
Initialise environment
    Create Directory    ${pdf_folder}
    Empty Directory    ${pdf_folder}
    Create Directory    ${screenshot_folder}
    Empty Directory    ${screenshot_folder}
    Say hello to user

Say hello to user
    Add text input    search    label="What is your name?"
    ${response}=    Run dialog
    Add text    Hello ${response}[search], we're about to start your robot- hold tight!
    Run dialog

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Element Is Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Close the annoying modal
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    ${orders_url}=    Get Secret    orders_url
    Download    ${orders_url}[URL]    overwrite=True    target_file=${orders_file}
    ${orders_table}=    Read table from CSV    path=${orders_file}
    [Return]    ${orders_table}

Fill the form
    [Arguments]    ${order_details}
    Set Local Variable    ${legs_element}    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Select From List By Index    id:head    ${order_details}[Head]
    Select Radio Button    body    ${order_details}[Body]
    Input Text    ${legs_element}    ${order_details}[Legs]
    Input Text    address    ${order_details}[Address]

Preview the robot
    Click Button    id:preview
    Page Should Contain Element    id:robot-preview-image

Submit the order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${receipt_pdf_filepath}    ${pdf_folder}${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${receipt_pdf_filepath}
    [Return]    ${receipt_pdf_filepath}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${screenshot_folder}${order_number}.png
    [Return]    ${screenshot_folder}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot_file}    ${PDF_file}
    Open PDF    ${PDF_file}
    @{myfiles}=    Create List    ${screenshot_file}:x=0,y=0
    Add Files To Pdf    ${myfiles}    ${PDF_FILE}    ${True}
    Close PDF    ${PDF_file}

Go to order another robot
    Click Button    id:order-another

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Close the browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Initialise environment
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10    3    Preview the robot
        Wait Until Keyword Succeeds    10    3    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser

Minimal task
    Log    Done.
