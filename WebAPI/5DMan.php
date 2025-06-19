<?php
// http://ruffo.ddns.net:8080/Github/ToTheCore/WebAPI/5DMan.php

// Error codes
abstract class ReturnCodes
{
    const Success = "returnCode = \"000 - Success.\"";
    const MySqlConnectError = "returnCode = \"001 - MySql connection failed.\"";

    const IdMissing = "returnCode = \"002 - No source id given.\"";
    const UnknownId = "returnCode = \"003 - Unknown source id. First register your client.\"";

    const RegistrationMissingParameter = "returnCode = \"110 - One of the following parameters are missing: Label\"";

    const TransferMissingParameter = "returnCode = \"120 - One of the following parameters are missing: Value, Targetlabel.\"";
    const TransferTargetNotFound = "returnCode = \"121 - The target computer does not exist.\"";

    const UnknownCommand = "returnCode = \"999 - Unknwon command.\"";
}
$databaseName = "ToTheCore";


// Connect to database.
$conn = new mysqli("localhost", "root", "");
if ($conn->connect_errno) {
    die(ReturnCodes::MySqlConnectError);
}
// Select database failed -> Create database, select.
if (!mysqli_select_db($conn, $databaseName)) {
    CreateDatabase($conn, $databaseName);
    mysqli_select_db($conn, $databaseName);
}

/**
 * Creates the database with the needed tables.
 * @param mysqli $conn MySqlI Connection
 * @param string $databaseName The database name.
 */
function CreateDatabase($conn, $databaseName)
{
    // Create database, if it not exists.
    $conn->query("CREATE DATABASE IF NOT EXISTS " . $databaseName . ";");
    mysqli_select_db($conn, $databaseName);

    // Create tables if it not exists.
    // -- table: computers
    $conn->query("CREATE TABLE IF NOT EXISTS computers
    (
        id int PRIMARY KEY AUTO_INCREMENT,
        label varchar(200),
        serverIp varchar(60)
    );");

    // -- table: transfers
    $conn->query("CREATE TABLE IF NOT EXISTS transfers
    (
        id int PRIMARY KEY AUTO_INCREMENT,
        value LONGTEXT,
        source int,
        target int,
        isScript tinyint(1),
        CONSTRAINT transfer_computers_id_fk FOREIGN KEY (source) REFERENCES computers (id),
        CONSTRAINT transfer_computers_id_fk_2 FOREIGN KEY (source) REFERENCES computers (id)
    );");
}

/**
 * Checks the given source id.
 * @throws string If no id sourceId given.
 * @throws string If the given sourceId is no existing computer.
 * @param int $sourceId The sourceId which should be checked.
 * @param mysqli $conn MySqlI Connection.
 * @return Object The whole computer dataset.
 */
function CheckSourceId($sourceId, $conn)
{
    // No id given -> die;
    if (!isset($_GET["sourceId"])) {
        die(ReturnCodes::IdMissing);
    }

    $result = $conn->query("SELECT * FROM computers WHERE id = " . $sourceId . " LIMIT 1;");

    // No computer with the given id -> die;
    if ($result->num_rows == 0) {
        die(ReturnCodes::UnknownId);
    }

    return $result->fetch_assoc();
}

/**
 * Registers a computer and returns the id of the computer.
 * @throws string If not all needed get parameters given.
 * @param mysqli $conn MySqlI Connection
 * @return int Id of the computer.
 */
function RegisterComputer($conn)
{
    // Not every parameter given -> die;
    if (!(isset($_GET["Label"]))) {
        die(ReturnCodes::RegistrationMissingParameter);
    }

    // Get parameters.
    $label = $_GET["Label"];
    $ip = isset($_SERVER['HTTP_CLIENT_IP']) ? $_SERVER['HTTP_CLIENT_IP'] : (isset($_SERVER['HTTP_X_FORWARDE‌​D_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : $_SERVER['REMOTE_ADDR']);

    // No registered computer found -> create new;
    $selectSql = "SELECT * FROM computers WHERE serverIp = '" . $ip . "' AND label = '" . $label . "' LIMIT 1;";
    $result = $conn->query($selectSql);
    if ($result->num_rows == 0) {
        //TODO: Error if the label is already given.
        //TODO: Unregister command.
        $conn->query("INSERT INTO `computers` (`label`, `serverIp`) VALUES ('$label', '$ip')");
        $result = $conn->query($selectSql);
    }
    $row = $result->fetch_assoc();
    return $row["id"];
}

function GetComputerTransfer($sourceId, $conn)
{
    $resultStr = "";
    $result = $conn->query("SELECT transfers.value as value, transfers.isScript as isScript, computers.label as sourceLabel FROM transfers, computers WHERE transfers.target = $sourceId AND computers.id = transfers.source;");
    if ($result->num_rows > 0) {
        // output data of each row
        while ($row = $result->fetch_assoc()) {

            // Parse value to lua string.
            $value = str_replace("\"", "\\\"", $row["value"]); // " -> \"

            $resultStr .= "{source = \"" . $row["sourceLabel"] . "\", value=\"" . $value . "\", isScript=" . ($row["isScript"] == 1 ? "true" : "false") . "},";
        }
        // Remove last ","
        $resultStr = substr($resultStr, 0, strlen($resultStr) - 1);

        // Delete fetched transfers.
        $conn->query("DELETE FROM transfers WHERE target = $sourceId");
    }
    return $resultStr;
}

function WriteTransfer($sourceId, $conn, $isScript)
{
    // Not every parameter given -> die;
    if (!(isset($_GET["TargetLabel"]) && isset($_GET["Value"]))) {
        die(ReturnCodes::TransferMissingParameter);
    }

    // Get values.
    $targetLabel = $_GET["TargetLabel"];
    $value = $_GET["Value"];

    // Get id of the TargetLabel
    $result = $conn->query("SELECT * FROM computers WHERE label = '$targetLabel' LIMIT 1;");
    // Target not found -> die;
    if ($result->num_rows == 0) {
        die(ReturnCodes::TransferTargetNotFound);
    }
    $targetRow = $result->fetch_assoc();

    // Write transfer dataset.
    $conn->query("INSERT INTO `transfers` (`value`, `source`, `target`, `isScript`) VALUES ('$value', $sourceId, " . $targetRow["id"] . ", " . ($isScript ? 1 : 0) . ")");
}

$command = $_GET["command"];
$sourceId = isset($_GET["sourceId"]) ? $_GET["sourceId"] : null;
$sourceComputer = null;

// Check id, set source computer object
if ($command != "recreateDatabase" && $command != "register") {
    $sourceComputer = CheckSourceId($sourceId, $conn);
}

switch ($command) {
    case 'recreateDatabase': //TODO: Add "config" with setting to block this command.
        ///http://ruffo.ddns.net:8080/Github/ToTheCore/WebAPI/5DMan.php?command=recreateDatabase
        // Drop old database.
        $conn->query("DROP DATABASE IF EXISTS " . $databaseName . ";");
        CreateDatabase($conn, $databaseName);
        die(ReturnCodes::Success);
        break;
    case 'register': //http://ruffo.ddns.net:8080/Github/ToTheCore/WebAPI/5DMan.php?command=register&Label=WebDebug
        echo "myId = " . RegisterComputer($conn) . "\n";
        die(ReturnCodes::Success);
        break;
    case 'fetch': // http://localhost:8080/Github/ToTheCore/WebAPI/5DMan.php?command=fetch&sourceId=3
        echo "result = {" . GetComputerTransfer($sourceId, $conn) . "}\n";
        die(ReturnCodes::Success);
        break;
    case 'send': // http://ruffo.ddns.net:8080/Github/ToTheCore/WebAPI/5DMan.php?command=send&sourceId=2&TargetLabel=WebDebug&Value=Console.WriteLine(Console.Type.Debug,"DebuggingShit")
        WriteTransfer($sourceId, $conn, false);
        die(ReturnCodes::Success);
        break;
    case 'sendScript': // http://ruffo.ddns.net:8080/Github/ToTheCore/WebAPI/5DMan.php?command=sendScript&sourceId=2&TargetLabel=WebDebug&Value=Console.WriteLine(Console.Type.Debug,"DebuggingShit")
        WriteTransfer($sourceId, $conn, true);
        die(ReturnCodes::Success);
        break;
    default:
        die(ReturnCodes::UnknownCommand);
        break;
}


?>
