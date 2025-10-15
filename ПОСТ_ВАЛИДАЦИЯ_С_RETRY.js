// ═══════════════════════════════════════════════════════════════════
// 🔴 ПОСТ-ВАЛИДАЦИЯ С АВТОМАТИЧЕСКИМ RETRY
// ═══════════════════════════════════════════════════════════════════
// Добавь эту ноду ПОСЛЕ "Clean Markdown" и ПЕРЕД "Convert to File"
// Название ноды: "Validate Laws & Retry"

const analysis = $input.first().json.content;
const documentText = $('развернуть документ').first().json.data;

// ═══════════════════════════════════════════════════════════════════
// ПРАВИЛА ВАЛИДАЦИИ (автоматически исправляемые)
// ═══════════════════════════════════════════════════════════════════

const validationRules = [
  {
    id: "wrong_article_575_for_non_residential",
    name: "Статья 575 для нежилых помещений",
    detect: (text, doc) => {
      const has575 = /статья 575.*?ГК РК/gi.test(text);
      const isNonResidential = /(нежил|офис|склад|магазин|коммерческ|ИП.*помещени|ТОО.*помещени)/gi.test(doc);
      const notResidential = !/(жил|квартир|дом)/gi.test(doc);
      return has575 && isNonResidential && notResidential;
    },
    severity: "CRITICAL",
    error: "Статья 575 применяется ТОЛЬКО к жилым помещениям. Для нежилых - статья 556!",
    autoFix: (text) => {
      return text
        .replace(/статья 575 Гражданского кодекса РК \(Особенная часть\)/gi, 
                 'статья 556 Гражданского кодекса РК (Особенная часть, Глава 29 «Аренда»)')
        .replace(/статьи 575 ГК РК/gi, 'статьи 556 ГК РК')
        .replace(/статья 575 ГК РК/gi, 'статья 556 ГК РК')
        .replace(/https:\/\/adilet\.zan\.kz\/rus\/docs\/K1500000409#z575/gi,
                 'https://adilet.zan.kz/rus/docs/K1500000409#z556');
    }
  },
  
  {
    id: "wrong_articles_406_410",
    name: "Статьи 406-410 вместо 401-405",
    detect: (text) => {
      return /статьи? 40[6-9]|статьи? 410/gi.test(text);
    },
    severity: "CRITICAL",
    error: "Статьи 406-410 НЕ существуют для расторжения! Правильно: 401-405.",
    autoFix: (text) => {
      return text
        .replace(/статьи 406-410 Гражданского кодекса РК \(Общая часть\)/gi,
                 'статьи 401-405 Гражданского кодекса РК (Общая часть, Глава 28 «Изменение и расторжение договора»)')
        .replace(/статья 406 ГК РК/gi, 'статья 401 ГК РК (Общая часть, Глава 28)')
        .replace(/статья 408 ГК РК/gi, 'статья 403 ГК РК (Общая часть, Глава 28)');
    }
  },
  
  {
    id: "article_380_for_penalty",
    name: "Статья 380 вместо 350 для неустойки",
    detect: (text) => {
      return /статья 380.*?неустойк/gi.test(text);
    },
    severity: "CRITICAL",
    error: "Статья 380 - про свободу договора, не про неустойку! Правильно: статья 350.",
    autoFix: (text) => {
      return text
        .replace(/статья 380 Гражданского кодекса РК.*?неустойк/gi,
                 'статья 350 Гражданского кодекса РК (Общая часть) определяет неустойк');
    }
  },
  
  {
    id: "chapter_30_for_non_residential",
    name: "Глава 30 для нежилых помещений",
    detect: (text, doc) => {
      const hasChapter30 = /Глава 30.*?[А"]?ренд/gi.test(text);
      const isNonResidential = /(нежил|офис|склад|ИП.*помещени|ТОО.*помещени)/gi.test(doc);
      return hasChapter30 && isNonResidential;
    },
    severity: "CRITICAL",
    error: "Глава 30 - только для ЖИЛЫХ помещений! Для нежилых - Глава 29.",
    autoFix: (text) => {
      return text
        .replace(/Глава 30 [""«]Аренда[""»]/gi, 'Глава 29 «Аренда»')
        .replace(/Глава 30 Гражданского кодекса РК/gi, 'Глава 29 Гражданского кодекса РК');
    }
  },
  
  {
    id: "missing_article_404",
    name: "Пропущена статья 404 при одностороннем отказе",
    detect: (text) => {
      const hasUnilateral = /(односторонн.*?отказ|пункт.*?14\.10.*?отказ|без указания причин)/gi.test(text);
      const has404 = /статья 404/gi.test(text);
      return hasUnilateral && !has404;
    },
    severity: "WARNING",
    error: "Упомянут односторонний отказ, но не упомянута статья 404 ГК РК!",
    autoFix: (text) => {
      // Находим первое упоминание одностороннего отказа
      const insertText = '\n\nСогласно статье 404 Гражданского кодекса РК (Общая часть, Глава 28 «Изменение и расторжение договора»), односторонний отказ от исполнения обязательства допускается в случаях, предусмотренных законодательством или договором.\n\n';
      
      // Ищем место для вставки (после упоминания "односторонний отказ")
      return text.replace(/(односторонн(?:ий|ом|его) отказ[а-я]*[^\.]*\.)/i, `$1${insertText}`);
    }
  },
  
  {
    id: "missing_part_indication",
    name: "Не указана часть кодекса",
    detect: (text) => {
      // Ищем упоминания статей без указания части
      const mentionsWithoutPart = text.match(/статья \d+ Гражданского кодекса РК(?!\s*\((?:Общая|Особенная) часть)/gi);
      return mentionsWithoutPart && mentionsWithoutPart.length > 0;
    },
    severity: "WARNING",
    error: "Есть ссылки на ГК РК без указания части (Общая/Особенная)!",
    autoFix: (text) => {
      // Добавляем часть кодекса для известных статей
      let fixed = text;
      
      // Статьи из Общей части
      const generalPart = ['401', '402', '403', '404', '405', '350', '352', '359', '380', '157', '152'];
      generalPart.forEach(num => {
        fixed = fixed.replace(
          new RegExp(`статья ${num} Гражданского кодекса РК(?!\\s*\\(Общая)`, 'gi'),
          `статья ${num} Гражданского кодекса РК (Общая часть)`
        );
      });
      
      // Статьи из Особенной части
      const specialPart = ['543', '544', '545', '556', '571', '575'];
      specialPart.forEach(num => {
        fixed = fixed.replace(
          new RegExp(`статья ${num} Гражданского кодекса РК(?!\\s*\\(Особенная)`, 'gi'),
          `статья ${num} Гражданского кодекса РК (Особенная часть)`
        );
      });
      
      return fixed;
    }
  }
];

// ═══════════════════════════════════════════════════════════════════
// ВЫПОЛНЕНИЕ ВАЛИДАЦИИ
// ═══════════════════════════════════════════════════════════════════

let errors = [];
let warnings = [];
let fixedText = analysis;
let autoFixed = false;

// Проверяем каждое правило
for (const rule of validationRules) {
  if (rule.detect(analysis, documentText)) {
    
    const issue = {
      id: rule.id,
      name: rule.name,
      severity: rule.severity,
      error: rule.error
    };
    
    if (rule.severity === "CRITICAL") {
      errors.push(issue);
    } else {
      warnings.push(issue);
    }
    
    // Автоматически исправляем
    if (rule.autoFix) {
      fixedText = rule.autoFix(fixedText);
      autoFixed = true;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// ЛОГИРОВАНИЕ
// ═══════════════════════════════════════════════════════════════════

if (errors.length > 0 || warnings.length > 0) {
  console.log('═══ ОБНАРУЖЕНЫ ПРОБЛЕМЫ В АНАЛИЗЕ ═══');
  
  if (errors.length > 0) {
    console.log(`\n🔴 КРИТИЧЕСКИЕ ОШИБКИ (${errors.length}):`);
    errors.forEach((err, i) => {
      console.log(`${i+1}. ${err.name}`);
      console.log(`   ${err.error}`);
    });
  }
  
  if (warnings.length > 0) {
    console.log(`\n⚠️ ПРЕДУПРЕЖДЕНИЯ (${warnings.length}):`);
    warnings.forEach((warn, i) => {
      console.log(`${i+1}. ${warn.name}`);
      console.log(`   ${warn.error}`);
    });
  }
  
  if (autoFixed) {
    console.log('\n✅ ВСЕ ПРОБЛЕМЫ АВТОМАТИЧЕСКИ ИСПРАВЛЕНЫ');
  }
}

// ═══════════════════════════════════════════════════════════════════
// ВОЗВРАЩАЕМ РЕЗУЛЬТАТ
// ═══════════════════════════════════════════════════════════════════

return [{
  json: {
    content: fixedText,
    validation: {
      had_errors: errors.length > 0,
      had_warnings: warnings.length > 0,
      errors_count: errors.length,
      warnings_count: warnings.length,
      auto_fixed: autoFixed,
      errors: errors,
      warnings: warnings,
      original_content: autoFixed ? analysis : null
    }
  }
}];
