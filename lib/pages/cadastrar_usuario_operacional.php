<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
$host = "localhost";
$user = "root";
$pass = "";
$db = "zeroone";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Erro na conexão: " . $conn->connect_error]);
    exit;
}
/*$data = json_decode(file_get_contents("php://input"), true);
$nome = $data["nome"] ?? '';
$email = $data["email"] ?? '';
$senha = $data["senha"] ?? '';

if (!$nome || !$email || !$senha) {
  echo json_encode(["success" => false, "message" => "Campos obrigatórios"]);
  exit;
}

$senhaHash = password_hash($senha, PASSWORD_DEFAULT);

$stmt = $conn->prepare("INSERT INTO usuarios_operacional (nome, email, senha) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $nome, $email, $senhaHash);

if ($stmt->execute()) {
  echo json_encode(["success" => true]);
} else {
  echo json_encode(["success" => false, "message" => $stmt->error]);
}
$stmt->close();
$conn->close();*/
?>