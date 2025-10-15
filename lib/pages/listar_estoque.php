<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$user = "root";
$pass = "";
$db = "zeroone";

$conn = new mysqli($host, $user, $pass, $db);


if($conn->connect_error){
    echo json_encode([
        "success" => false,
        "message" => "Falha na conexão com o Banco de Dados" . $conn->connect_error
    ]);
    exit;
}

$sql = "SELECT * FROM estoque ORDER BY nome";
$result = $conn->query($sql);

$itens = [];
while ($row = $result->fetch_assoc()) {
    $itens[] = $row;
}

echo json_encode(["success" => true, "itens" => $itens]);
?>