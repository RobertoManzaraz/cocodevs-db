-- =====================================================================
-- E-COMMERCE · Esquema básico (PostgreSQL)
-- 11 tablas: usuarios, catálogo, carrito, pedidos, pagos y facturas
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. USUARIOS
-- ---------------------------------------------------------------------
CREATE TABLE roles (
    id      int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  varchar(50) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rol_id         int          NOT NULL REFERENCES roles(id),
    email          varchar(255) NOT NULL UNIQUE,
    password_hash  varchar(255) NOT NULL,
    nombre         varchar(100) NOT NULL,
    apellido       varchar(100) NOT NULL,
    telefono       varchar(30),
    activo         boolean      NOT NULL DEFAULT true,   -- en vez de borrar usuarios, se desactivan
    created_at     timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE direcciones (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id     bigint       NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    alias          varchar(50),                          -- "Casa", "Trabajo"
    calle          varchar(150) NOT NULL,
    ciudad         varchar(100) NOT NULL,
    provincia      varchar(100) NOT NULL,
    codigo_postal  varchar(20)  NOT NULL,
    pais           varchar(100) NOT NULL DEFAULT 'Argentina'
);

-- ---------------------------------------------------------------------
-- 2. CATÁLOGO
-- ---------------------------------------------------------------------
CREATE TABLE categorias (
    id                  int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_padre_id  int          REFERENCES categorias(id) ON DELETE SET NULL,  -- subcategorías
    nombre              varchar(100) NOT NULL,
    slug                varchar(120) NOT NULL UNIQUE                                -- "televisores-led"
);

CREATE TABLE productos (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_id  int           NOT NULL REFERENCES categorias(id),
    sku           varchar(64)   NOT NULL UNIQUE,
    nombre        varchar(200)  NOT NULL,
    descripcion   text,
    marca         varchar(100),
    imagen_url    varchar(500),
    precio        numeric(12,2) NOT NULL CHECK (precio >= 0),
    stock         int           NOT NULL DEFAULT 0 CHECK (stock >= 0),
    activo        boolean       NOT NULL DEFAULT true,   -- ocultar producto sin borrarlo
    created_at    timestamptz   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 3. CARRITO (un carrito por usuario; se vacía al comprar)
-- ---------------------------------------------------------------------
CREATE TABLE carritos (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id  bigint      NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE carrito_items (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    carrito_id   bigint NOT NULL REFERENCES carritos(id)   ON DELETE CASCADE,
    producto_id  bigint NOT NULL REFERENCES productos(id)  ON DELETE CASCADE,
    cantidad     int    NOT NULL CHECK (cantidad > 0),
    UNIQUE (carrito_id, producto_id)                      -- un producto una sola vez por carrito
);

-- ---------------------------------------------------------------------
-- 4. PEDIDOS
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id          bigint        NOT NULL REFERENCES usuarios(id),
    direccion_envio_id  bigint        NOT NULL REFERENCES direcciones(id),
    estado              varchar(20)   NOT NULL DEFAULT 'pendiente'
                        CHECK (estado IN ('pendiente','pagado','enviado','entregado','cancelado')),
    total               numeric(12,2) NOT NULL CHECK (total >= 0),
    created_at          timestamptz   NOT NULL DEFAULT now()
);

CREATE TABLE detalle_pedidos (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id        bigint        NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id      bigint        NOT NULL REFERENCES productos(id),
    cantidad         int           NOT NULL CHECK (cantidad > 0),
    precio_unitario  numeric(12,2) NOT NULL CHECK (precio_unitario >= 0),   -- precio al momento de comprar
    subtotal         numeric(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    UNIQUE (pedido_id, producto_id)
);

-- ---------------------------------------------------------------------
-- 5. PAGOS Y FACTURAS
-- ---------------------------------------------------------------------
CREATE TABLE transacciones_pagos (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id    bigint        NOT NULL REFERENCES pedidos(id),
    metodo_pago  varchar(50)   NOT NULL,                  -- "tarjeta", "transferencia", "mercadopago"
    monto        numeric(12,2) NOT NULL CHECK (monto > 0),
    estado       varchar(20)   NOT NULL DEFAULT 'pendiente'
                 CHECK (estado IN ('pendiente','aprobado','rechazado','reembolsado')),
    created_at   timestamptz   NOT NULL DEFAULT now()
);

CREATE TABLE facturas (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id       bigint        NOT NULL UNIQUE REFERENCES pedidos(id),   -- una factura por pedido
    numero_factura  varchar(50)   NOT NULL UNIQUE,
    total           numeric(12,2) NOT NULL CHECK (total >= 0),
    fecha_emision   timestamptz   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 6. ÍNDICES (PostgreSQL no los crea solo en las claves foráneas)
-- ---------------------------------------------------------------------
CREATE INDEX idx_usuarios_rol          ON usuarios(rol_id);
CREATE INDEX idx_direcciones_usuario   ON direcciones(usuario_id);
CREATE INDEX idx_categorias_padre      ON categorias(categoria_padre_id);
CREATE INDEX idx_productos_categoria   ON productos(categoria_id);
CREATE INDEX idx_carrito_items_prod    ON carrito_items(producto_id);
CREATE INDEX idx_pedidos_usuario       ON pedidos(usuario_id);
CREATE INDEX idx_detalle_producto      ON detalle_pedidos(producto_id);
CREATE INDEX idx_pagos_pedido          ON transacciones_pagos(pedido_id);
