--!strict
-- Tipos da loja (sem lógica), para os dados (Bundles) e as regras usarem os
-- mesmos nomes sem depender uns dos outros.
export type SpinKind = "normal" | "paid" -- "paid" = giro especial

-- Uma coisa que um produto entrega. Os campos dependem do kind (Shop/Rewards).
export type Reward = {
	kind: string,
	id: string?,
	amount: number?,
	count: number?,
	spin: SpinKind?,
}

-- Um pacote em destaque como escrito em Shop/Bundles.luau.
export type BundleDef = {
	id: string,
	nameKey: string,
	theme: string,
	rarity: number,
	robux: number,
	startsAt: string?,
	endsAt: string?,
	rewards: { Reward },
}

export type Price = { currency: "robux" | "ember", amount: number }
export type ProductKind = "bundle" | "pack" | "spins" | "kitOnce" | "kit" | "pass"

-- Tudo que se compra. `once` = cada jogador compra uma vez só.
export type Product = {
	id: string,
	kind: ProductKind,
	price: Price,
	once: boolean,
	startsAt: number?,
	endsAt: number?,
	rewards: { Reward },
	nameKey: string?,
	order: number,
}

return nil
