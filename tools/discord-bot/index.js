const {
	Client,
	GatewayIntentBits,
	Partials,
	EmbedBuilder,
	ActionRowBuilder,
	ButtonBuilder,
	ButtonStyle,
	ModalBuilder,
	TextInputBuilder,
	TextInputStyle,
	Events,
} = require("discord.js");
require("dotenv").config();

// ============================================================================
// EMBER WILDS | OFFICIAL DISCORD BOT
// 1. Outbound Auto-Translation (PT-BR -> 7 Language Zones: EN, ES, FR, DE, RU, TR, PH)
//    for Rules, FAQ, Announcements, Updates & Sneak Peeks.
// 2. Inbound Player Feedback Aggregator (All 8 Languages -> PT-BR in 🔒 STAFF & DEV)
//    Aggregates all Suggestions -> #💡│todas-sugestoes and Bugs -> #🐛│todos-bugs
//    with automatic translation to PT-BR, player identification, attachments,
//    and a direct link button ("🔗 Ir para Mensagem Original").
// 3. Protects codes inside (), -...-, `...`, and ALL-CAPS tokens from translation.
// 4. Button-only Language Role Selector in #🌐│choose-language (no duplicate reactions).
// 5. Auto-assigns @Survivor role on join.
// ============================================================================

const CONFIG = {
	guildId: "1572656111176130664",

	// 1. Outbound PT-BR Official Channels -> 7 Target Language Zones
	mirrorChannels: {
		// #📜│regras-pt -> all 7 Rules channels
		"1572665896370053150": [
			{ targetId: "1572663676643967078", lang: "en" }, // 🇺🇸 rules-en
			{ targetId: "1572684038240600106", lang: "es" }, // 🇪🇸 reglas-es
			{ targetId: "1572684096642089101", lang: "fr" }, // 🇫🇷 regles-fr
			{ targetId: "1572684164782882938", lang: "de" }, // 🇩🇪 regeln-de
			{ targetId: "1572684218637488150", lang: "ru" }, // 🇷🇺 правила-ru
			{ targetId: "1572684267270570215", lang: "tr" }, // 🇹🇷 kurallar-tr
			{ targetId: "1572684324208119989", lang: "tl" }, // 🇵🇭 rules-ph
		],

		// #❓│faq-pt -> all 7 FAQ channels
		"1572665978284818563": [
			{ targetId: "1572663699590877184", lang: "en" }, // 🇺🇸 faq-en
			{ targetId: "1572684047317213294", lang: "es" }, // 🇪🇸 faq-es
			{ targetId: "1572684106784055357", lang: "fr" }, // 🇫🇷 faq-fr
			{ targetId: "1572684171086929950", lang: "de" }, // 🇩🇪 faq-de
			{ targetId: "1572684228553089055", lang: "ru" }, // 🇷🇺 faq-ru
			{ targetId: "1572684276384927914", lang: "tr" }, // 🇹🇷 sss-tr
			{ targetId: "1572684336396771379", lang: "tl" }, // 🇵🇭 faq-ph
		],

		// #📢│anuncios-pt -> all 7 Announcements channels
		"1572666013563228160": [
			{ targetId: "1572663719207637062", lang: "en" }, // 🇺🇸 announcements-en
			{ targetId: "1572684055735173182", lang: "es" }, // 🇪🇸 anuncios-es
			{ targetId: "1572684114480463942", lang: "fr" }, // 🇫🇷 annonces-fr
			{ targetId: "1572684179706220654", lang: "de" }, // 🇩🇪 ankuendigungen-de
			{ targetId: "1572684234252882081", lang: "ru" }, // 🇷🇺 объявления-ru
			{ targetId: "1572684283070390395", lang: "tr" }, // 🇹🇷 duyurular-tr
			{ targetId: "1572684344714330145", lang: "tl" }, // 🇵🇭 announcements-ph
		],

		// #🛠️│atualizacoes-pt -> all 7 Updates channels
		"1572666031367917629": [
			{ targetId: "1572663745438548060", lang: "en" }, // 🇺🇸 updates-en
			{ targetId: "1572684063892832366", lang: "es" }, // 🇪🇸 actualizaciones-es
			{ targetId: "1572684123951071263", lang: "fr" }, // 🇫🇷 mises-a-jour-fr
			{ targetId: "1572684187062771833", lang: "de" }, // 🇩🇪 updates-de
			{ targetId: "1572684241010167851", lang: "ru" }, // 🇷🇺 обновления-ru
			{ targetId: "1572684291878551824", lang: "tr" }, // 🇹🇷 guncellemeler-tr
			{ targetId: "1572684353295876227", lang: "tl" }, // 🇵🇭 updates-ph
		],

		// #👀│sneak-peeks-pt -> all 7 Sneak Peeks channels
		"1572666119771398224": [
			{ targetId: "1572663767626416158", lang: "en" }, // 🇺🇸 sneak-peeks-en
			{ targetId: "1572684065272766624", lang: "es" }, // 🇪🇸 sneak-peeks-es
			{ targetId: "1572684126069461122", lang: "fr" }, // 🇫🇷 sneak-peeks-fr
			{ targetId: "1572684188669444257", lang: "de" }, // 🇩🇪 sneak-peeks-de
			{ targetId: "1572684242708865204", lang: "ru" }, // 🇷🇺 sneak-peeks-ru
			{ targetId: "1572684293388378152", lang: "tr" }, // 🇹🇷 sneak-peeks-tr
			{ targetId: "1572684354629537890", lang: "tl" }, // 🇵🇭 sneak-peeks-ph
		],
	},

	// 2. Inbound Player Feedback Channels -> Staff & Dev Hub Channels (Translated to PT-BR)
	staffHub: {
		allSuggestionsChannelId: "1572685447434604624", // #💡│todas-sugestoes
		allBugsChannelId: "1572685450186072164", // #🐛│todos-bugs

		suggestionChannels: {
			"1572659286591545404": { name: "💡│sugestoes-pt", langLabel: "🇧🇷 Português", langCode: "pt" },
			"1572663859909623819": { name: "💡│suggestions-en", langLabel: "🇺🇸 English", langCode: "en" },
			"1572684068947230811": { name: "💡│sugerencias-es", langLabel: "🇪🇸 Español", langCode: "es" },
			"1572684140678086666": { name: "💡│suggestions-fr", langLabel: "🇫🇷 Français", langCode: "fr" },
			"1572684193467605042": { name: "💡│vorschlaege-de", langLabel: "🇩🇪 Deutsch", langCode: "de" },
			"1572684247167271012": { name: "💡│предложения-ru", langLabel: "🇷🇺 Русский", langCode: "ru" },
			"1572684297805234176": { name: "💡│oneriler-tr", langLabel: "🇹🇷 Türkçe", langCode: "tr" },
			"1572684358630903809": { name: "💡│suggestions-ph", langLabel: "🇵🇭 Filipino", langCode: "tl" },
		},

		bugChannels: {
			"1572659306103316680": { name: "🐛│bugs-pt", langLabel: "🇧🇷 Português", langCode: "pt" },
			"1572663889802305536": { name: "🐛│bugs-en", langLabel: "🇺🇸 English", langCode: "en" },
			"1572684078174703710": { name: "🐛│bugs-es", langLabel: "🇪🇸 Español", langCode: "es" },
			"1572684151155597403": { name: "🐛│bugs-fr", langLabel: "🇫🇷 Français", langCode: "fr" },
			"1572684204133589143": { name: "🐛│bugs-de", langLabel: "🇩🇪 Deutsch", langCode: "de" },
			"1572684255375392768": { name: "🐛│баги-ru", langLabel: "🇷🇺 Русский", langCode: "ru" },
			"1572684307804192818": { name: "🐛│hatalar-tr", langLabel: "🇹🇷 Türkçe", langCode: "tr" },
			"1572684367938064484": { name: "🐛│bugs-ph", langLabel: "🇵🇭 Filipino", langCode: "tl" },
		},
	},

	channels: {
		chooseLanguage: "1572658880335454289",
		verifyRoblox: "1572658895141216419",
		influencerPublic: "1572687379196809306", // #🎥│influencer-program
		influencerReview: "1572687383286128823", // #🎥│candidaturas-influencer
		modLogs: "1572659633959600308", // #📋│mod-logs
	},

	// Anti-Spam & Cooldown Settings
	antiSpam: {
		langButtonCooldownMs: 3000, // 3s between language button clicks
		feedbackCooldownMs: 3 * 60 * 1000, // 3 minutes per user between Dev Hub suggestions/bugs
		feedbackMinChars: 12, // Minimum 12 characters for valid suggestion/bug text (unless attachment included)
		influencerApplyCooldownMs: 24 * 60 * 60 * 1000, // 24 hours between influencer applications
		chatWindowMs: 8000, // 8s rolling window for flood check
		chatMaxMessagesInWindow: 5, // 5+ messages in 8s -> auto delete + 2 min timeout
		chatMaxDuplicateMessages: 3, // 3 identical messages in a row -> auto delete + 2 min timeout
		timeoutDurationMs: 2 * 60 * 1000, // 2 minutes timeout
	},

	roles: {
		english: "1572661602027835582",
		portugues: "1572661656671092756",
		espanol: "1572682217266741428",
		francais: "1572682218386489374",
		deutsch: "1572682219607036015",
		russkiy: "1572682220580372625",
		turkce: "1572682221918093342",
		filipino: "1572682223382036521",
		verified: "1572661719841374238",
		survivor: "1572657486266110073",
		influencer: "1572687216491102348", // 🎥 Influencer / Creator
	},

	languageMeta: {
		lang_en: {
			roleId: "1572661602027835582",
			emoji: "🇺🇸",
			addedMsg: "🇺🇸 Welcome! You now have access to the **🇺🇸 ENGLISH ZONE**!",
			removedMsg: "🇺🇸 Removed the **English** role.",
		},
		lang_pt: {
			roleId: "1572661656671092756",
			emoji: "🇧🇷",
			addedMsg: "🇧🇷 Bem-vindo(a)! Agora você tem acesso à **🇧🇷 ZONA PORTUGUÊS**!",
			removedMsg: "🇧🇷 Cargo **Português** removido.",
		},
		lang_es: {
			roleId: "1572682217266741428",
			emoji: "🇪🇸",
			addedMsg: "🇪🇸 ¡Bienvenido(a)! Ahora tienes acceso a la **🇪🇸 ZONA ESPAÑOL**.",
			removedMsg: "🇪🇸 Rol **Español** eliminado.",
		},
		lang_fr: {
			roleId: "1572682218386489374",
			emoji: "🇫🇷",
			addedMsg: "🇫🇷 Bienvenue ! Vous avez maintenant accès à la **🇫🇷 ZONE FRANÇAIS**.",
			removedMsg: "🇫🇷 Rôle **Français** retiré.",
		},
		lang_de: {
			roleId: "1572682219607036015",
			emoji: "🇩🇪",
			addedMsg: "🇩🇪 Willkommen! Du hast nun Zugriff auf die **🇩🇪 DEUTSCH ZONE**.",
			removedMsg: "🇩🇪 Rolle **Deutsch** entfernt.",
		},
		lang_ru: {
			roleId: "1572682220580372625",
			emoji: "🇷🇺",
			addedMsg: "🇷🇺 Добро пожаловать! Теперь вам доступна **🇷🇺 РУССКАЯ ЗОНА**.",
			removedMsg: "🇷🇺 Роль **Русский** удалена.",
		},
		lang_tr: {
			roleId: "1572682221918093342",
			emoji: "🇹🇷",
			addedMsg: "🇹🇷 Hoş geldiniz! Artık **🇹🇷 TÜRKÇE BÖLGESİ** kategorisine erişebilirsiniz.",
			removedMsg: "🇹🇷 **Türkçe** rolü kaldırıldı.",
		},
		lang_ph: {
			roleId: "1572682223382036521",
			emoji: "🇵🇭",
			addedMsg: "🇵🇭 Maligayang pagdating! May access ka na sa **🇵🇭 FILIPINO ZONE**.",
			removedMsg: "🇵🇭 Inalis ang **Filipino** role.",
		},
	},
};

/**
 * Multi-provider translation fallback (dict-chrome-ex -> clients5 -> MyMemory -> gtx)
 */
async function callTranslatorProvider(text, sourceLang = "pt", targetLang = "en") {
	if (sourceLang === targetLang) return text;
	const providers = [
		async (q) => {
			const res = await fetch(
				`https://translate.googleapis.com/translate_a/single?client=dict-chrome-ex&sl=${sourceLang}&tl=${targetLang}&dt=t&q=` +
					encodeURIComponent(q),
				{
					headers: {
						"User-Agent":
							"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36",
					},
				}
			);
			if (!res.ok) throw new Error(`dict-chrome-ex HTTP ${res.status}`);
			const data = await res.json();
			return data[0].map((segment) => segment[0]).join("");
		},
		async (q) => {
			const res = await fetch(
				`https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=${sourceLang}&tl=${targetLang}&q=` +
					encodeURIComponent(q),
				{
					headers: {
						"User-Agent":
							"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36",
					},
				}
			);
			if (!res.ok) throw new Error(`clients5 HTTP ${res.status}`);
			const data = await res.json();
			if (Array.isArray(data)) {
				return typeof data[0] === "string"
					? data[0]
					: Array.isArray(data[0])
						? data[0][0]
						: String(data);
			}
			throw new Error("Unexpected clients5 format");
		},
		async (q) => {
			const sl = sourceLang === "auto" ? "en" : sourceLang;
			const res = await fetch(
				"https://api.mymemory.translated.net/get?q=" +
					encodeURIComponent(q) +
					`&langpair=${sl}|${targetLang}`
			);
			if (!res.ok) throw new Error(`MyMemory HTTP ${res.status}`);
			const data = await res.json();
			if (data?.responseData?.translatedText) {
				return data.responseData.translatedText;
			}
			throw new Error("Unexpected MyMemory format");
		},
		async (q) => {
			const res = await fetch(
				`https://translate.googleapis.com/translate_a/single?client=gtx&sl=${sourceLang}&tl=${targetLang}&dt=t&q=` +
					encodeURIComponent(q)
			);
			if (!res.ok) throw new Error(`gtx HTTP ${res.status}`);
			const data = await res.json();
			return data[0].map((segment) => segment[0]).join("");
		},
	];

	let lastErr = null;
	for (const provider of providers) {
		try {
			const out = await provider(text);
			if (out && out.trim()) return out;
		} catch (err) {
			lastErr = err;
		}
	}
	throw lastErr || new Error("All translation providers failed");
}

/**
 * Translates text from sourceLang to targetLang while protecting:
 * - Code blocks & inline code (`...`)
 * - Text inside parentheses `(...)`
 * - Text inside hyphens `-...-`
 * - ALL-CAPS promo codes (4+ chars, e.g. LANCAMENTO2026)
 * - Discord mentions, custom emojis, and URLs
 */
async function translateText(text, sourceLang = "pt", targetLang = "en") {
	if (!text || !text.trim()) return "";
	if (sourceLang === targetLang) return text;

	let processed = text;
	if (sourceLang === "pt") {
		for (const [ptChanId, targetList] of Object.entries(CONFIG.mirrorChannels)) {
			const matchTarget = targetList.find((t) => t.lang === targetLang);
			if (matchTarget) {
				processed = processed.replaceAll(`<#${ptChanId}>`, `<#${matchTarget.targetId}>`);
			}
		}
	}

	const placeholders = [];
	const protect = (match) => {
		const token = `[[TK_${placeholders.length}]]`;
		placeholders.push(match);
		return token;
	};

	// 1. Code blocks & inline backticks
	processed = processed.replace(/```[\s\S]*?```|`[^`\n]+`/g, protect);

	// 2. Discord mentions, custom emojis, and URLs
	processed = processed.replace(
		/(<[@#][!&]?\d+>|<a?:[a-zA-Z0-9_]+:\d+>|https?:\/\/[^\s)]+)/g,
		protect
	);

	// 3. Text inside parentheses: ( ... )
	processed = processed.replace(/\([^()\n]+\)/g, protect);

	// 4. Text inside hyphens: -...-
	processed = processed.replace(/(?:^|(?<=\s))-[^\s-][^\n-]*-[^\s-]*(?=\s|$|[.,!?])/g, protect);

	// 5. Standalone ALL-CAPS promo codes (4+ uppercase/digits/underscores)
	processed = processed.replace(/\b[A-Z0-9_]{4,}\b/g, protect);

	try {
		let translated = await callTranslatorProvider(processed, sourceLang, targetLang);

		placeholders.forEach((original, idx) => {
			const regex = new RegExp(`\\[\\s*\\[\\s*TK_?${idx}\\s*\\]\\s*\\]`, "gi");
			translated = translated.replace(regex, original);
		});

		translated = translated.replace(/Ember Wilds/gi, "Ember Wilds");
		return translated;
	} catch (err) {
		console.error(`[Translate Error ${sourceLang} -> ${targetLang}]`, err.message);
		return text;
	}
}

const client = new Client({
	intents: [
		GatewayIntentBits.Guilds,
		GatewayIntentBits.GuildMembers,
		GatewayIntentBits.GuildMessages,
		GatewayIntentBits.MessageContent,
	],
	partials: [Partials.Message, Partials.Channel, Partials.User],
});

// Track mirrored message IDs: PT message ID -> Array of { targetChannelId, targetMessageId, lang }
const mirroredMessages = new Map();
// Track player feedback hub cards: source message ID -> { hubChannelId, hubMessageId, sourceInfo, isBug }
const feedbackMessages = new Map();

// Cooldown & Anti-Spam state trackers
const langButtonCooldowns = new Map(); // userId -> timestamp
const feedbackCooldowns = new Map(); // `${userId}_${isBug ? 'bug' : 'sug'}` -> { timestamp, lastHash }
const influencerCooldowns = new Map(); // userId -> timestamp
const userChatTracker = new Map(); // userId -> { timestamps: number[], lastContent: string, dupCount: number }

function isStaffMember(member) {
	if (!member) return false;
	return member.roles.cache.some(
		(r) =>
			r.name.includes("Founder") ||
			r.name.includes("Developer") ||
			r.name.includes("Administrator") ||
			r.name.includes("Moderator")
	);
}

client.once(Events.ClientReady, async (readyClient) => {
	console.log(`🔥 Ember Wilds Bot is online as ${readyClient.user.tag}!`);
	console.log(
		`📡 Outbound Auto-Translation: PT-BR (#regras-pt, #faq-pt, #anuncios-pt, #atualizacoes-pt, #sneak-peeks-pt) -> 7 Language Zones (EN, ES, FR, DE, RU, TR, PH)`
	);
	console.log(
		`📥 Inbound Dev Hub: All 8 Suggestion & Bug channels -> #💡│todas-sugestoes & #🐛│todos-bugs (Translated to PT-BR with Original Message Link)`
	);

	// Ensure #🎥│influencer-program button is 100% English ("Apply for Influencer")
	try {
		const infChan = await client.channels.fetch(CONFIG.channels.influencerPublic);
		if (infChan && infChan.isTextBased()) {
			const msgs = await infChan.messages.fetch({ limit: 5 });
			const botMsg = msgs.find((m) => m.author.id === readyClient.user.id);
			if (botMsg) {
				const applyRow = new ActionRowBuilder().addComponents(
					new ButtonBuilder()
						.setCustomId("influencer_apply_btn")
						.setLabel("Apply for Influencer")
						.setEmoji("🎥")
						.setStyle(ButtonStyle.Primary)
				);
				await botMsg.edit({ components: [applyRow] });
				console.log("✅ Updated #🎥│influencer-program button to 100% English");
			}
		}
	} catch (err) {
		console.warn("Could not update influencer button:", err.message);
	}
});

/**
 * Builds the rich Dev Hub embed + jump link button for a player's suggestion or bug report
 */
async function buildFeedbackCard(message, sourceInfo, isBug) {
	const rawContent = message.content || "";
	const isPt = sourceInfo.langCode === "pt";
	const translatedPt = isPt
		? rawContent
		: await translateText(rawContent, "auto", "pt");

	const embed = new EmbedBuilder()
		.setColor(isBug ? 0xe74c3c : 0xf1c40f)
		.setAuthor({
			name: `${message.author.globalName || message.author.username} (@${message.author.username})`,
			iconURL: message.author.displayAvatarURL({ size: 128 }),
		})
		.setTitle(
			isBug
				? `🐛 Novo Reporte de Bug (${sourceInfo.langLabel})`
				: `💡 Nova Sugestão (${sourceInfo.langLabel})`
		)
		.addFields(
			{
				name: "👤 Jogador",
				value: `<@${message.author.id}> (\`${message.author.id}\`)`,
				inline: true,
			},
			{
				name: "🌍 Canal de Origem",
				value: `<#${message.channel.id}> (${sourceInfo.langLabel})`,
				inline: true,
			}
		)
		.setTimestamp(message.createdAt);

	if (isPt) {
		embed.setDescription(
			`### 🇧🇷 Mensagem:\n${rawContent || "*[Apenas anexo / mídia]*"}`
		);
	} else {
		embed.setDescription(
			`### 🇧🇷 Tradução Automática (PT-BR):\n${translatedPt || "*[Apenas anexo / mídia]*"}\n\n` +
				`### 📄 Mensagem Original (${sourceInfo.langLabel}):\n> ${(rawContent || "*[Sem texto]*").replace(/\n/g, "\n> ")}`
		);
	}

	// Attach first image preview inside the embed if the player uploaded a screenshot
	const firstImage = message.attachments.find((a) =>
		a.contentType ? a.contentType.startsWith("image/") : /\.(png|jpe?g|gif|webp)$/i.test(a.name)
	);
	if (firstImage) {
		embed.setImage(firstImage.url);
	}

	if (message.attachments.size > 0) {
		const attLinks = message.attachments
			.map((a) => `• [${a.name}](${a.url})`)
			.join("\n");
		embed.addFields({
			name: `📎 Anexos (${message.attachments.size})`,
			value: attLinks,
		});
	}

	const row = new ActionRowBuilder().addComponents(
		new ButtonBuilder()
			.setLabel("🔗 Ir para Mensagem Original")
			.setStyle(ButtonStyle.Link)
			.setURL(message.url)
	);

	return { embeds: [embed], components: [row] };
}

client.on(Events.MessageCreate, async (message) => {
	if (message.author.bot) return;

	// 0. Global Anti-Flood & Duplicate Message Filter for non-Staff members
	if (message.guild && !isStaffMember(message.member)) {
		const now = Date.now();
		const userId = message.author.id;
		const normalized = (message.content || "").trim().toLowerCase();

		let tracker = userChatTracker.get(userId);
		if (!tracker) {
			tracker = { timestamps: [], lastContent: "", dupCount: 0 };
			userChatTracker.set(userId, tracker);
		}

		tracker.timestamps = tracker.timestamps.filter(
			(ts) => now - ts < CONFIG.antiSpam.chatWindowMs
		);
		tracker.timestamps.push(now);

		if (normalized.length > 0 && normalized === tracker.lastContent) {
			tracker.dupCount += 1;
		} else {
			tracker.lastContent = normalized;
			tracker.dupCount = 1;
		}

		const isFlood = tracker.timestamps.length >= CONFIG.antiSpam.chatMaxMessagesInWindow;
		const isDupSpam = tracker.dupCount >= CONFIG.antiSpam.chatMaxDuplicateMessages;

		if (isFlood || isDupSpam) {
			await message.delete().catch(() => {});
			tracker.timestamps = [];
			tracker.dupCount = 0;

			// Apply 2-minute timeout so the spammer stops immediately
			if (message.member && message.member.moderatable) {
				await message.member
					.timeout(
						CONFIG.antiSpam.timeoutDurationMs,
						isFlood ? "AutoMod: Message flood spam" : "AutoMod: Repeated duplicate messages"
					)
					.catch(() => {});
			}

			// Log in #📋│mod-logs
			try {
				const modLogs = await client.channels.fetch(CONFIG.channels.modLogs);
				if (modLogs && modLogs.isTextBased()) {
					const logEmbed = new EmbedBuilder()
						.setColor(0xe74c3c)
						.setTitle("🛡️ Anti-Spam Action — User Timed Out (2m)")
						.addFields(
							{
								name: "👤 User",
								value: `<@${userId}> (\`${userId}\`)`,
								inline: true,
							},
							{
								name: "📍 Channel",
								value: `<#${message.channel.id}>`,
								inline: true,
							},
							{
								name: "⚠️ Reason",
								value: isFlood
									? "Message Flood (5+ messages in 8 seconds)"
									: "Duplicate Spam (3+ identical messages in a row)",
								inline: false,
							}
						)
						.setTimestamp();
					await modLogs.send({ embeds: [logEmbed] });
				}
			} catch {
				// ignore log error
			}
			return;
		}
	}

	// A) Check if this is an official PT-BR post to mirror across the 7 language zones
	const targets = CONFIG.mirrorChannels[message.channel.id];
	if (targets && targets.length > 0) {
		const mirroredList = [];

		await Promise.all(
			targets.map(async (targetCfg) => {
				try {
					const targetChannel = await client.channels.fetch(targetCfg.targetId);
					if (!targetChannel || !targetChannel.isTextBased()) return;

					const translatedContent = await translateText(
						message.content,
						"pt",
						targetCfg.lang
					);

					const files = message.attachments.map((att) => ({
						attachment: att.url,
						name: att.name,
					}));

					const embeds = [];
					for (const emb of message.embeds) {
						const newEmbed = EmbedBuilder.from(emb);
						if (emb.title)
							newEmbed.setTitle(
								await translateText(emb.title, "pt", targetCfg.lang)
							);
						if (emb.description)
							newEmbed.setDescription(
								await translateText(emb.description, "pt", targetCfg.lang)
							);
						embeds.push(newEmbed);
					}

					const sent = await targetChannel.send({
						content: translatedContent || undefined,
						files: files.length > 0 ? files : undefined,
						embeds: embeds.length > 0 ? embeds : undefined,
					});

					mirroredList.push({
						targetChannelId: targetChannel.id,
						targetMessageId: sent.id,
						lang: targetCfg.lang,
					});

					console.log(
						`[Mirrored PT -> ${targetCfg.lang.toUpperCase()}] ${message.channel.name} -> ${targetChannel.name} (${message.id} -> ${sent.id})`
					);
				} catch (err) {
					console.error(`[Mirror Error -> ${targetCfg.lang}]`, err.message);
				}
			})
		);

		if (mirroredList.length > 0) {
			mirroredMessages.set(message.id, mirroredList);
		}
		return;
	}

	// B) Check if this is a Player Suggestion or Bug Report in ANY of the 8 language zones
	const suggestionSource = CONFIG.staffHub.suggestionChannels[message.channel.id];
	const bugSource = CONFIG.staffHub.bugChannels[message.channel.id];

	if (suggestionSource || bugSource) {
		const isBug = Boolean(bugSource);
		const sourceInfo = bugSource || suggestionSource;
		const cleanText = (message.content || "").trim();
		const isStaff = isStaffMember(message.member);

		// Anti-troll / short-gibberish filter on Suggestions & Bug Reports (unless Staff or has media attachment)
		if (
			!isStaff &&
			cleanText.length < CONFIG.antiSpam.feedbackMinChars &&
			message.attachments.size === 0
		) {
			await message.delete().catch(() => {});
			const warnMsg = await message.channel
				.send(
					`⚠️ <@${message.author.id}> Please write a detailed ${isBug ? "bug report" : "suggestion"} (at least ${CONFIG.antiSpam.feedbackMinChars} characters) following the pinned template!`
				)
				.catch(() => null);
			if (warnMsg) {
				setTimeout(() => warnMsg.delete().catch(() => {}), 8000);
			}
			return;
		}

		// Per-user cooldown & duplicate check on Dev Hub forwarding
		const fbKey = `${message.author.id}_${isBug ? "bug" : "sug"}`;
		const prevFb = feedbackCooldowns.get(fbKey);
		const now = Date.now();
		if (!isStaff && prevFb) {
			const isSameText =
				cleanText.length > 0 && cleanText.toLowerCase() === prevFb.lastHash;
			const withinCooldown = now - prevFb.timestamp < CONFIG.antiSpam.feedbackCooldownMs;
			if (isSameText || withinCooldown) {
				await message.delete().catch(() => {});
				const remainingSec = Math.ceil(
					(CONFIG.antiSpam.feedbackCooldownMs - (now - prevFb.timestamp)) / 1000
				);
				const warnMsg = await message.channel
					.send(
						`⏳ <@${message.author.id}> Please wait **${remainingSec}s** before submitting another ${isBug ? "bug report" : "suggestion"}.`
					)
					.catch(() => null);
				if (warnMsg) {
					setTimeout(() => warnMsg.delete().catch(() => {}), 7000);
				}
				return;
			}
		}
		feedbackCooldowns.set(fbKey, {
			timestamp: now,
			lastHash: cleanText.toLowerCase(),
		});

		const hubChannelId = isBug
			? CONFIG.staffHub.allBugsChannelId
			: CONFIG.staffHub.allSuggestionsChannelId;

		try {
			const hubChannel = await client.channels.fetch(hubChannelId);
			if (!hubChannel || !hubChannel.isTextBased()) return;

			const cardPayload = await buildFeedbackCard(message, sourceInfo, isBug);
			const hubMsg = await hubChannel.send(cardPayload);

			// Add a subtle reaction on the player's message to confirm it was received by the Dev Hub
			await message.react(isBug ? "🛠️" : "💡").catch(() => {});

			feedbackMessages.set(message.id, {
				hubChannelId: hubChannel.id,
				hubMessageId: hubMsg.id,
				sourceInfo,
				isBug,
			});

			console.log(
				`[Dev Hub ${isBug ? "BUG" : "SUGGESTION"}] Forwarded from #${message.channel.name} by ${message.author.tag} -> #${hubChannel.name}`
			);
		} catch (err) {
			console.error("[Dev Hub Forward Error]", err.message);
		}
	}
});

// Sync message edits (both Outbound PT->7 langs and Inbound Player Feedback->Dev Hub)
client.on(Events.MessageUpdate, async (_oldMsg, newMsg) => {
	if (newMsg.partial) {
		try {
			await newMsg.fetch();
		} catch {
			return;
		}
	}
	if (newMsg.author?.bot) return;

	// A) Sync Outbound Official Edits
	const mirrorList = mirroredMessages.get(newMsg.id);
	if (mirrorList) {
		await Promise.all(
			mirrorList.map(async (mirrorInfo) => {
				try {
					const targetChannel = await client.channels.fetch(mirrorInfo.targetChannelId);
					if (!targetChannel || !targetChannel.isTextBased()) return;
					const targetMsg = await targetChannel.messages.fetch(
						mirrorInfo.targetMessageId
					);
					if (!targetMsg) return;

					const translatedContent = await translateText(
						newMsg.content,
						"pt",
						mirrorInfo.lang
					);
					await targetMsg.edit({ content: translatedContent || undefined });
					console.log(
						`[Synced Edit PT -> ${mirrorInfo.lang.toUpperCase()}] ${newMsg.id} -> ${targetMsg.id}`
					);
				} catch (err) {
					console.error("[Mirror Edit Error]", err.message);
				}
			})
		);
	}

	// B) Sync Inbound Player Feedback Edits in Dev Hub
	const fbInfo = feedbackMessages.get(newMsg.id);
	if (fbInfo) {
		try {
			const hubChannel = await client.channels.fetch(fbInfo.hubChannelId);
			if (!hubChannel || !hubChannel.isTextBased()) return;
			const hubMsg = await hubChannel.messages.fetch(fbInfo.hubMessageId);
			if (!hubMsg) return;

			const updatedCard = await buildFeedbackCard(newMsg, fbInfo.sourceInfo, fbInfo.isBug);
			await hubMsg.edit(updatedCard);
			console.log(`[Synced Feedback Edit] Updated Dev Hub card ${hubMsg.id}`);
		} catch (err) {
			console.error("[Feedback Edit Error]", err.message);
		}
	}
});

// Sync message deletions
client.on(Events.MessageDelete, async (message) => {
	const mirrorList = mirroredMessages.get(message.id);
	if (mirrorList) {
		await Promise.all(
			mirrorList.map(async (mirrorInfo) => {
				try {
					const targetChannel = await client.channels.fetch(mirrorInfo.targetChannelId);
					if (!targetChannel || !targetChannel.isTextBased()) return;
					const targetMsg = await targetChannel.messages.fetch(
						mirrorInfo.targetMessageId
					);
					if (targetMsg) await targetMsg.delete();
				} catch (err) {
					console.error("[Mirror Delete Error]", err.message);
				}
			})
		);
		mirroredMessages.delete(message.id);
	}

	const fbInfo = feedbackMessages.get(message.id);
	if (fbInfo) {
		try {
			const hubChannel = await client.channels.fetch(fbInfo.hubChannelId);
			if (hubChannel && hubChannel.isTextBased()) {
				const hubMsg = await hubChannel.messages.fetch(fbInfo.hubMessageId);
				if (hubMsg) await hubMsg.delete();
			}
		} catch (err) {
			console.error("[Feedback Delete Error]", err.message);
		}
		feedbackMessages.delete(message.id);
	}
});

// Language Selection & Influencer Program Interactions (Buttons + Modals)
client.on(Events.InteractionCreate, async (interaction) => {
	// A) Button Interactions
	if (interaction.isButton()) {
		// 1. Language Role Toggle Buttons (with anti-spam click cooldown)
		const meta = CONFIG.languageMeta[interaction.customId];
		if (meta) {
			const now = Date.now();
			const lastClick = langButtonCooldowns.get(interaction.user.id) || 0;
			if (now - lastClick < CONFIG.antiSpam.langButtonCooldownMs) {
				await interaction.reply({
					content: "⏳ Please wait a few seconds before toggling language roles again.",
					ephemeral: true,
				});
				return;
			}
			langButtonCooldowns.set(interaction.user.id, now);

			const member = interaction.member;
			try {
				const hasRole = member.roles.cache.has(meta.roleId);
				if (hasRole) {
					await member.roles.remove(meta.roleId);
					await interaction.reply({
						content: meta.removedMsg,
						ephemeral: true,
					});
				} else {
					await member.roles.add(meta.roleId);
					await interaction.reply({
						content: meta.addedMsg,
						ephemeral: true,
					});
				}
			} catch (err) {
				console.error("[Role Button Error]", err);
				await interaction.reply({
					content: "❌ Could not update your role. Please check bot role hierarchy.",
					ephemeral: true,
				});
			}
			return;
		}

		// 2. Open Influencer Application Modal (with 24h anti-spam cooldown & role check)
		if (interaction.customId === "influencer_apply_btn") {
			const isStaff = isStaffMember(interaction.member);
			if (!isStaff && interaction.member?.roles?.cache?.has(CONFIG.roles.influencer)) {
				await interaction.reply({
					content: "🎥 You already have the **🎥 Influencer / Creator** role!",
					ephemeral: true,
				});
				return;
			}
			const lastApp = influencerCooldowns.get(interaction.user.id) || 0;
			const now = Date.now();
			if (!isStaff && now - lastApp < CONFIG.antiSpam.influencerApplyCooldownMs) {
				const hoursLeft = Math.ceil(
					(CONFIG.antiSpam.influencerApplyCooldownMs - (now - lastApp)) / (60 * 60 * 1000)
				);
				await interaction.reply({
					content: `⏳ You have already submitted an Influencer application recently. Please wait **${hoursLeft}h** before applying again.`,
					ephemeral: true,
				});
				return;
			}
			const modal = new ModalBuilder()
				.setCustomId("influencer_apply_modal")
				.setTitle("🎥 Influencer / Creator Application");

			const robloxInput = new TextInputBuilder()
				.setCustomId("inf_roblox")
				.setLabel("Roblox Username (for in-game items)")
				.setPlaceholder("e.g. Builderman")
				.setStyle(TextInputStyle.Short)
				.setRequired(true)
				.setMaxLength(50);

			const channelInput = new TextInputBuilder()
				.setCustomId("inf_channel")
				.setLabel("Channel Link (YouTube / TikTok / Twitch)")
				.setPlaceholder("e.g. https://youtube.com/@yourchannel")
				.setStyle(TextInputStyle.Short)
				.setRequired(true)
				.setMaxLength(200);

			const statsInput = new TextInputBuilder()
				.setCustomId("inf_stats")
				.setLabel("Followers / Subscribers & Avg Views")
				.setPlaceholder("e.g. 12,500 subscribers, ~3,000 views per video")
				.setStyle(TextInputStyle.Short)
				.setRequired(true)
				.setMaxLength(150);

			const videoInput = new TextInputBuilder()
				.setCustomId("inf_video")
				.setLabel("Ember Wilds / Roblox Video Link & Notes")
				.setPlaceholder("Paste your video link and tell us about your content!")
				.setStyle(TextInputStyle.Paragraph)
				.setRequired(true)
				.setMaxLength(800);

			modal.addComponents(
				new ActionRowBuilder().addComponents(robloxInput),
				new ActionRowBuilder().addComponents(channelInput),
				new ActionRowBuilder().addComponents(statsInput),
				new ActionRowBuilder().addComponents(videoInput)
			);

			await interaction.showModal(modal);
			return;
		}

		// 3. Staff Approve Influencer Button: inf_approve_<userId>
		if (interaction.customId.startsWith("inf_approve_")) {
			const targetUserId = interaction.customId.replace("inf_approve_", "");
			try {
				const guild = interaction.guild;
				const targetMember = await guild.members.fetch(targetUserId).catch(() => null);
				if (targetMember) {
					await targetMember.roles.add(CONFIG.roles.influencer);
				}

				const oldEmbed = interaction.message.embeds[0];
				const updatedEmbed = EmbedBuilder.from(oldEmbed)
					.setColor(0x2ecc71)
					.setTitle("✅ Candidatura de Influencer — APROVADA")
					.addFields({
						name: "🛡️ Decisão da Staff",
						value: `Aprovado por <@${interaction.user.id}> em <t:${Math.floor(Date.now() / 1000)}:f>\nCargo <@&${CONFIG.roles.influencer}> entregue automaticamente!`,
					});

				await interaction.update({
					embeds: [updatedEmbed],
					components: [],
				});

				// Notify applicant via DM (100% English)
				if (targetMember) {
					await targetMember
						.send(
							"🎉 **Congratulations!**\n\n" +
								"Your application for the **Ember Wilds Official Influencer / Creator Program** has been **APPROVED**! You have received the **🎥 Influencer / Creator** role on Discord, and our team has registered your Roblox username for your in-game Creator rewards!"
						)
						.catch(() => {});
				}
			} catch (err) {
				console.error("[Influencer Approve Error]", err);
				await interaction.reply({
					content: `❌ Erro ao aprovar candidatura: ${err.message}`,
					ephemeral: true,
				});
			}
			return;
		}

		// 4. Staff Reject Influencer Button: inf_reject_<userId> -> Opens optional reason modal
		if (interaction.customId.startsWith("inf_reject_")) {
			const targetUserId = interaction.customId.replace("inf_reject_", "");
			const modal = new ModalBuilder()
				.setCustomId(`inf_reject_modal_${targetUserId}_${interaction.message.id}`)
				.setTitle("❌ Recusar Candidatura de Influencer");

			const reasonInput = new TextInputBuilder()
				.setCustomId("reject_reason")
				.setLabel("Motivo da recusa (opcional)")
				.setPlaceholder("Ex: Ainda não atingiu o mínimo de visualizações ou inscritos.")
				.setStyle(TextInputStyle.Paragraph)
				.setRequired(false)
				.setMaxLength(400);

			modal.addComponents(new ActionRowBuilder().addComponents(reasonInput));
			await interaction.showModal(modal);
			return;
		}
	}

	// B) Modal Submissions
	if (interaction.isModalSubmit()) {
		// 1. Player submitted Influencer Application
		if (interaction.customId === "influencer_apply_modal") {
			await interaction.deferReply({ ephemeral: true });
			influencerCooldowns.set(interaction.user.id, Date.now());

			const robloxUser = interaction.fields.getTextInputValue("inf_roblox").trim();
			const channelUrl = interaction.fields.getTextInputValue("inf_channel").trim();
			const statsText = interaction.fields.getTextInputValue("inf_stats").trim();
			const videoNotes = interaction.fields.getTextInputValue("inf_video").trim();

			try {
				const reviewChan = await client.channels.fetch(CONFIG.channels.influencerReview);
				if (reviewChan && reviewChan.isTextBased()) {
					const translatedStats = await translateText(statsText, "auto", "pt");
					const translatedNotes = await translateText(videoNotes, "auto", "pt");

					const reviewEmbed = new EmbedBuilder()
						.setColor(0xff2a85)
						.setAuthor({
							name: `${interaction.user.globalName || interaction.user.username} (@${interaction.user.username})`,
							iconURL: interaction.user.displayAvatarURL({ size: 128 }),
						})
						.setTitle("🎥 Nova Candidatura de Influencer / Creator")
						.addFields(
							{
								name: "👤 Candidato (Discord)",
								value: `<@${interaction.user.id}> (\`${interaction.user.id}\`)`,
								inline: true,
							},
							{
								name: "🎮 Nick no Roblox (para entregar itens)",
								value: `\`${robloxUser}\``,
								inline: true,
							},
							{
								name: "🔗 Canal / Plataforma",
								value: channelUrl,
								inline: false,
							},
							{
								name: "📊 Inscritos / Seguidores e Média de Views (Traduzido PT-BR)",
								value:
									translatedStats !== statsText
										? `${translatedStats}\n*(Original: ${statsText})*`
										: statsText,
								inline: false,
							},
							{
								name: "🎬 Link do Vídeo e Observações (Traduzido PT-BR)",
								value:
									translatedNotes !== videoNotes
										? `${translatedNotes}\n\n**Original:**\n> ${videoNotes.replace(/\n/g, "\n> ")}`
										: videoNotes,
								inline: false,
							}
						)
						.setTimestamp();

					const decisionRow = new ActionRowBuilder().addComponents(
						new ButtonBuilder()
							.setCustomId(`inf_approve_${interaction.user.id}`)
							.setLabel("Aprovar e Dar Cargo")
							.setEmoji("✅")
							.setStyle(ButtonStyle.Success),
						new ButtonBuilder()
							.setCustomId(`inf_reject_${interaction.user.id}`)
							.setLabel("Recusar")
							.setEmoji("❌")
							.setStyle(ButtonStyle.Danger)
					);

					await reviewChan.send({
						embeds: [reviewEmbed],
						components: [decisionRow],
					});
				}

				await interaction.editReply({
					content:
						"✅ **Application Submitted!**\n\n" +
						"Your Influencer application has been sent to the **Ember Wilds** team! You will receive a DM from the bot once your application is reviewed.",
				});
			} catch (err) {
				console.error("[Influencer Submit Error]", err);
				await interaction.editReply({
					content: "❌ Could not submit application. Please try again later.",
				});
			}
			return;
		}

		// 2. Staff submitted Reject Reason Modal
		if (interaction.customId.startsWith("inf_reject_modal_")) {
			const parts = interaction.customId.replace("inf_reject_modal_", "").split("_");
			const targetUserId = parts[0];
			const reviewMsgId = parts[1];
			const reasonPt =
				interaction.fields.getTextInputValue("reject_reason")?.trim() ||
				"Requisitos mínimos ainda não atingidos.";

			try {
				const reviewChan = interaction.channel;
				const reviewMsg = await reviewChan.messages.fetch(reviewMsgId).catch(() => null);
				const reasonEn = await translateText(reasonPt, "pt", "en");

				if (reviewMsg) {
					const oldEmbed = reviewMsg.embeds[0];
					const updatedEmbed = EmbedBuilder.from(oldEmbed)
						.setColor(0xe74c3c)
						.setTitle("❌ Candidatura de Influencer — RECUSADA")
						.addFields({
							name: "🛡️ Decisão da Staff",
							value: `Recusado por <@${interaction.user.id}> em <t:${Math.floor(Date.now() / 1000)}:f>\n**Motivo:** ${reasonPt}`,
						});

					await reviewMsg.edit({
						embeds: [updatedEmbed],
						components: [],
					});
				}

				const targetUser = await client.users.fetch(targetUserId).catch(() => null);
				if (targetUser) {
					await targetUser
						.send(
							"🎥 **Ember Wilds — Influencer Application Update**\n\n" +
								`Thank you for applying to the **Ember Wilds Creator Program**! Unfortunately, your application was not approved at this time.\n**Reason:** ${reasonEn}\n*Feel free to apply again in the future once you meet all requirements!*`
						)
						.catch(() => {});
				}

				await interaction.reply({
					content: "✅ Candidatura marcada como recusada e candidato notificado.",
					ephemeral: true,
				});
			} catch (err) {
				console.error("[Influencer Reject Modal Error]", err);
				await interaction.reply({
					content: `❌ Erro ao recusar candidatura: ${err.message}`,
					ephemeral: true,
				});
			}
		}
	}
});

// Auto-assign @Survivor role when a new member joins
client.on(Events.GuildMemberAdd, async (member) => {
	try {
		await member.roles.add(CONFIG.roles.survivor);
	} catch (err) {
		console.error("[Auto-Role Error]", err.message);
	}
});

if (!process.env.DISCORD_BOT_TOKEN) {
	console.error("❌ Missing DISCORD_BOT_TOKEN in .env file!");
	process.exit(1);
}

client.login(process.env.DISCORD_BOT_TOKEN);
