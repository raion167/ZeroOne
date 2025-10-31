<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$user = "root";
$pass = "";
$db = "zeroone";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Erro de conexão: " . $conn->connect_error]));
}

$sql = "SELECT id, nome, quantidade, preco, data_cadastro FROM estoque ORDER BY nome ASC";

$result = $conn->query($sql);

if (!$result) {
    die(json_encode(["success" => false, "message" => "Erro na query: " . $conn->error]));
}

$materiais = [];
while ($row = $result->fetch_assoc()) {
    $materiais[] = $row;
}

echo json_encode(["success" => true, "materiais" => $materiais], JSON_UNESCAPED_UNICODE);
$conn->close();
?>