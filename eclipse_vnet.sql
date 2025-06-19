-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 13-06-2025 a las 23:41:52
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `eclipse_vnet`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `administrador`
--

CREATE TABLE `administrador` (
  `ci_rif` varchar(20) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `telefono` varchar(20) CHARACTER SET armscii8 COLLATE armscii8_general_ci NOT NULL,
  `USUARIO` varchar(20) DEFAULT NULL,
  `CONTRASEÑA` varchar(20) DEFAULT NULL,
  `sucursal` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `administrador`
--

INSERT INTO `administrador` (`ci_rif`, `nombre`, `telefono`, `USUARIO`, `CONTRASEÑA`, `sucursal`) VALUES
('1234567', 'gregory', '', 'programador', '12345678', 'Caracas');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `Nro_cuenta` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `ci_rif` varchar(20) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `municipio` varchar(20) DEFAULT NULL,
  `sector` varchar(20) DEFAULT NULL,
  `plan_contrato` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contratistas`
--

CREATE TABLE `contratistas` (
  `ci_rif` varchar(20) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `USUARIO` varchar(20) DEFAULT NULL,
  `CONTRASEÑA` varchar(20) DEFAULT NULL,
  `correo` varchar(20) DEFAULT NULL,
  `sucursal` varchar(20) DEFAULT NULL,
  `cuadrillas` int(11) DEFAULT NULL,
  `cuadrilla1` varchar(50) DEFAULT NULL,
  `cuadrilla2` varchar(50) DEFAULT NULL,
  `cuadrilla3` varchar(50) DEFAULT NULL,
  `cuadrilla4` varchar(50) DEFAULT NULL,
  `cuadrilla5` text NOT NULL,
  `cuadrilla6` text NOT NULL,
  `cuadrilla7` text NOT NULL,
  `cuadrilla8` text NOT NULL,
  `cuadrilla9` text NOT NULL,
  `cuadrilla10` text NOT NULL,
  `instalaciones_exitosas` int(11) DEFAULT NULL,
  `instalaciones_fallidas` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `doc.ordenes`
--

CREATE TABLE `doc.ordenes` (
  `id` int(11) NOT NULL,
  `dato_cliente` varchar(300) NOT NULL,
  `ont_1puerto` int(11) DEFAULT NULL,
  `conector_SC_APC` int(11) DEFAULT NULL,
  `pathcore_scapc_apcsc` int(11) DEFAULT NULL,
  `roseta` int(11) DEFAULT NULL,
  `scapc_adapter` int(11) DEFAULT NULL,
  `ont_4puertos` int(11) DEFAULT NULL,
  `conector_scupc` int(11) DEFAULT NULL,
  `canaletas` int(11) DEFAULT NULL,
  `cable_drop` varchar(20) DEFAULT NULL,
  `cantidad_cabledrop` int(11) DEFAULT NULL,
  `potencia_cajanap` float DEFAULT NULL,
  `potencia_ont` float NOT NULL,
  `mac_ont` varchar(20) DEFAULT NULL,
  `serial_ont` varchar(20) DEFAULT NULL,
  `puerto_nap` varchar(20) DEFAULT NULL,
  `nroequipos_conectar` int(11) DEFAULT NULL,
  `etiqueta_cliente` varchar(30) DEFAULT NULL,
  `router` varchar(50) DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `hora_inicio` time DEFAULT NULL,
  `hora_final` time DEFAULT NULL,
  `Contratista` varchar(30) DEFAULT NULL,
  `nombre_cliente` varchar(30) DEFAULT NULL,
  `firma_cliente` blob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ordenes_instalacion`
--

CREATE TABLE `ordenes_instalacion` (
  `Nro_cuenta` int(20) NOT NULL,
  `fecha_hora1` datetime DEFAULT NULL,
  `fecha_hora2` datetime DEFAULT NULL,
  `comentario_cliente` text NOT NULL,
  `Nro_orden` int(20) DEFAULT NULL,
  `contratista` varchar(20) DEFAULT NULL,
  `estado` text CHARACTER SET armscii8 COLLATE armscii8_general_ci NOT NULL,
  `usuarioID` varchar(20) DEFAULT NULL,
  `contraseñaID` varchar(20) DEFAULT NULL,
  `aradial_olt` tinyint(1) DEFAULT NULL,
  `verificacion_red` tinyint(1) NOT NULL,
  `observacion_contratista` text DEFAULT NULL,
  `latitud` double DEFAULT NULL,
  `longitud` double DEFAULT NULL,
  `hora_inicio` time DEFAULT NULL,
  `hora_final` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `administrador`
--
ALTER TABLE `administrador`
  ADD PRIMARY KEY (`ci_rif`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`Nro_cuenta`),
  ADD UNIQUE KEY `ci_rif` (`ci_rif`);

--
-- Indices de la tabla `contratistas`
--
ALTER TABLE `contratistas`
  ADD PRIMARY KEY (`ci_rif`);

--
-- Indices de la tabla `doc.ordenes`
--
ALTER TABLE `doc.ordenes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `ordenes_instalacion`
--
ALTER TABLE `ordenes_instalacion`
  ADD PRIMARY KEY (`Nro_cuenta`),
  ADD UNIQUE KEY `Nro_orden` (`Nro_orden`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `doc.ordenes`
--
ALTER TABLE `doc.ordenes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
