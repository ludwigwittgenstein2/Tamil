// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  pagenumbering: "1",
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
\usepackage{titlesec}

% Two-column spacing
\setlength{\columnsep}{18pt}
\setlength{\columnseprule}{0.4pt}

% Bold headings with rule under sections
\titleformat{\section}
  {\large\bfseries}
  {\thesection.}{0.5em}{}[\vspace{1pt}\titlerule]

\titleformat{\subsection}
  {\normalsize\bfseries}
  {\thesubsection.}{0.5em}{}

\titleformat{\subsubsection}
  {\small\bfseries\itshape}
  {\thesubsubsection.}{0.5em}{}

\titlespacing*{\section}{0pt}{10pt}{4pt}
\titlespacing*{\subsection}{0pt}{7pt}{3pt}
\titlespacing*{\subsubsection}{0pt}{5pt}{2pt}

% Make TOC title bigger
\renewcommand{\contentsname}{\Large\bfseries Table of Contents}

\setlength{\parindent}{0.15in}
\setlength{\parskip}{4pt}

#show: doc => article(
  title: [Modern History of China],
  subtitle: [Notes from Jeffrey Wasserstrom's, Oxford History of Modern China],
  authors: (
    ( name: [Rick Rejeleene],
      affiliation: [],
      email: [] ),
    ),
  date: [April 25, 2026],
  sectionnumbering: "1.1.a",
  pagenumbering: "1",
  toc: true,
  toc_title: [Table of Contents],
  toc_depth: 2,
  cols: 1,
  doc,
)

= History of China
<history-of-china>
From Tamil Nadu's perspective or curriculum; there was not much that I can recall from my high-school curriculum or even middle school, covering History of China.

These days, for regular folks, China is a symbol of development and one party rule. In the early 2000s, many South Indians, including many Tamils, viewed China largely through the lens of cheap manufactured goods, rather than as a state that had paired industrial policy, skills formation, and centralized long-term planning into a development model.

I selected Jeffrey Wasserstrom's, Oxford History of Modern China. Somethings are so interesting, while popular discourse might speak of China as 5000 year continous civilization, it was not the case, there's been lot of changing borders, dynastic collapse, internal rebellion. In the introduction, earlier china had different borders, it was mostly inner China only.

= Ming and Qing China
<ming-and-qing-china>
Around 1550, China was ruled by the Ming dynasty, and it was already one of the most sophisticated societies in the world. Most people were farmers. But agriculture wasn't primitive. Rice cultivation in southern China supported dense populations, and regional markets linked villages to cities. During early and late ming era 1500-1600s, China experienced something like a commercial boom, where the key feature of its economy was silver payments, instead of grain or labor. Cities like Suzhou, Hangzhou, Nanjing expanded. China was the largest consumer of silver. From 1644, Manchus captured power, and founded Qing dynasty.

What's surpassing is that Qing were outsiders, they were not Han. Manchus were, a sedentary farming people from northeast Asia (Manchuria) who were culturally and ethnically distinct from the Han Chinese majority they conquered. Qing dynasty expanded, conquered, Xinjiang, asserted authority in Tibet, controlled Mongolia, and strengthened their rule in Mongolia. Much of China's territory is shaped during Qing rule. Qing emperors carefully adopted Confucian traditions to gain legitimacy among Han elites, they did not change Chinese political culture. In 1700s, during times of Kangxi Emperor, Yongzheng Emperor, and Qianlong Emperor, China experienced prosperity and stability. It was during this time, population increased dramatically, Agricultural output rose, trade expanded and the empire looked strong and secure.

= Britain, Opium, and Treaty Ports
<britain-opium-and-treaty-ports>
This all changed from 1793, Britain sent diplomat George Macartney to negotiate expanded trade access with the Qing court. Britain wanted port access, permanent embassy, equal diplomatic status. The Qing emperor Qianlong Emperor asked the diplomat to kowtow, three kneelings and nine knockings of the head on the ground to recognize, the Emperor as the supreme ruler of the Celestial Empire. Lord Macartney refused, he instead performed instead knelt on one knee.

He presented the Qianlong Emperor with various British goods designed to showcase technological superiority and stimulate trade, including a Herschel telescope, a planetarium, artillery pieces, and textiles from Bolton. He also delivered a letter from King George III requesting open trade ports and a permanent British embassy. The Qianlong Emperor dismissed all of this and said, China possessed all things and had no need for British goods. Qianlong's letter referenced all Europeans as "barbarians", his assumption of all nations of the earth as being subordinate to China. Macartney left in anger, wrote a long pamphlet on how the Qing dynasty would end.

Britain wanted Chinese tea, silk and porcelain. China only wanted silver, and this became a serious economic concern for Britain. To solve this deficit, Britain begins exporting opium to China. British traders began selling opium illegally into China, suddenly all levels of Chinese social life were addicted to this new substance. By 1830s, The Qing court started debating whether to legalize opium or ban it completely.

The court decided to ban it and appointed strict Lin Zexu as a commissioner to Guangzhou, which was the main trading port. Lin Zexu took strong action, arrested opium traders, confiscated over 20,000 chests of opium. From the British perspective, this was destruction of private property belonging to British merchants. British Parliament leaders were debating on how China had violated trade rights, British citizens had been mistreated, British property had been destroyed.

British sailors killed a Chinese man, Lin Weix in 1839, Qing authorities demanded that the guilty sailor be handed over for Chinese justice, The British superintendent, Charles Elliot, refused, because Britain did not want its subjects tried under Qing law. British Parliament leaders settled for war and attacking the ports, and so the first opium war began. In this, China was defeated and signed the famous, Treaty of Nanjing. This treaty allowed open Britain to have access to five treaty ports, pay large indemnities, give Britain Hong Kong, allow British merchants expanded rights.

Shortly after, in 1856, Qing emperor faced Second Opium war, where both United Kingdom and France joined to fight over the right to import opium to China, and resulted in a second defeat for the Qing and the forced legalisation of the opium trade. The emperor was forced to sign concessions, where foreign diplomats permanently allowed in Beijing, missionary protection given, and opium trade effectively legalized.

= Rebellion and Failed Reform
<rebellion-and-failed-reform>
Taiping Rebellion was a long 14 year civil war that took place from 1850-1864, where the leader Hong believed, he was brother of Jesus and wanted a new Heaven on earth, his kingdom established. The goal was to overthrow the Qing dynasty, almost 20 million people died in the rebellion on both sides.

After 1860 and until 1900, the country tried to modernize, the Qing dynasty survived, however it did not have the strength, it went through a period of restoration as it encountered foreigners through two opium wars. It was a new world of foreign gunboats, treaty ports, missionaries, diplomats, customs offices, steamships, telegraphs, and international law. Qing empire lost in the Sino-Japanese War (1894--95), this caused a huge blow to China.

Qing introduced the Zongli Yamen, a new institution to handle foreign affairs, it was however more the place for technology transfer, diplomatic communication, translation, and translating foreign expertise to their country. In late 1800s, many were pushing for modernization, reform noticing Meiji Japan, and implemented the short-lived Hundred Days' Reform (1898), where the emperor tried to rapidly modernize Education, Military, Government, Economy. One of the major figures was Kang Youwei, a Chinese scholar, who was persuading the country to become a constitutional monarchy. Many of the reforms were technological, not institutional. The reforms failed as it was highly fast paced change, and Empress Cixi pushed back.

Soon after the reforms failed, Boxer rebellion took place, which was in 1899, the goal was to eradicate the foreigners, but the rebellion was squashed by foreign power alliance of Japan, Russia, Britain, France, Germany, Austria-Hungary, Italy.

After the defeat, the leaders considered serious reforms and began reforming passing Xinzheng policy reforming institutions, abolishing the 1000 years imperial exams (1905) and introducing Beiyang Army. It was too late to save the Qing empire.

= Revolution and Republic
<revolution-and-republic>
All this lead to political thinkers like Sun Yat-sen for supporting modernization, who believed China needed independence, democracy, economic fairness.

Later, indirectly the failed reforms, fueled the Chinese 1911 Revolution, leading to the birth, Republic of China. In 1912, the last Qing emperor abdicated, this ended more than two thousand years of imperial rule and started the most important political transition for Chinese history. From 1919-1937, after the collapse of empire, China fragmented, and republic was in name only, power was divided among regional armies, political factions, and competing visions of the future. The central government was not powerful enough to control, stabilize, as widespread corruption, region warlords started to appear, foreign pressure continuing in the country.

This lead the educated Chinese to wonder, what they needed to do more for helping their country? Maybe it was China's political traditions, social structure, education system, and even culture needed transformation.

= Communists, Nationalists, and Japan
<communists-nationalists-and-japan>
It was in 1921, the Chinese communist party was found, it was a small group, who were mostly influenced by Russian Revolution and by Marxist ideas about class struggle and social transformation. Early members included intellectuals, teachers, and activists rather than peasants or soldiers. For them, the weakness was inequality in their social structure, and workers and peasants should play a central role in building a new society.

During this time, China entered a period of war lord era, Sun Yat-sen cooperated with the Chinese communist party, for unifying china. After Sun Yat Sen's death, Chiang Kai lead the Nationalist government established its capital in Nanjing and claimed authority over much of China. However the cooperation between communist party and Nationalist party was short-lived.

Japan was controlling parts of China, and by 1937, full scale war began between China and Japan, with Japan expanding, and city of Nanjing fell, with the horrific Nanjing Massacre. Communists under Mao Zedong developed rural support networks, organized the peasants, carried out land reforms. By the end of World War 2, the communist party had political legitimacy from rural side of China and built political legitimacy among villagers. And by 1949, the communist party defeated nationalist party, and the Chiang Kai-shek's government retreated to Taiwan.

= Mao, Revolution, and Disaster
<mao-revolution-and-disaster>
China came under Mao's rule and during this time of Chinese history from, 1949--1965, the government redistributed land from landlords to peasants, reorganized industry under state control, following Soviet Union model of development. The First Five-Year Plan emphasized heavy industry like steel and machinery, Cities expanded and industrial production increased. However, Mao found dissatisfaction of this model and wanted china to have its own model, which lead towards the policy of Great Leap Forward.

Mao believed China could accelerate development by mobilizing rural labor on a massive scale, Farmers were encouraged to produce steel in backyard furnaces, result was catastrophic, Agricultural output fell. Food shortages spread. A devastating famine followed. After this, China entered cultural revolution from 1966--1976. Mao believed the Communist Party itself was becoming too bureaucratic and conservative, Students known as Red Guards attacked teachers, officials, and intellectuals accused of being “counter-revolutionary, millions were persecuted. It produced instability across the country. When Mao died in 1976, China was at a crossroads on which path to continue?

= Deng Xiaoping and Reform China
<deng-xiaoping-and-reform-china>
Deng Xiaoping believed, China needed economic modernization, rather than ideological champions. China launched a reform program that changed its development strategy completely. Rural communes were dismantled. Farmers gained more control over production. Private business slowly returned. Foreign investment entered special economic zones like Shenzhen.

This was reform and opening, the reform started with rural provinces, rather than foreign investment or factories. What makes it remarkable is that China remained politically Communist while becoming economically more market-oriented. The economic growth also create inequality, social tension, corruption, In 1989, students and citizens gathered in Beijing to demand political reform and accountability. These protests became known worldwide as the Tiananmen Square protest.

The government eventually used military force to end the protests. It continued economic reform but avoided political liberalization. During 1990s, 2000s, Factories multiplied. Cities grew. Millions moved from villages to urban areas. Trade increased rapidly after China joined the World Trade Organization in 2001 and by early 21st century, China had become a central player in the global economy. Earlier reform-era leadership emphasized collective decision-making inside the Communist Party, Under Xi, political authority has become more centralized again, His government launched major anti-corruption campaigns, strengthened party discipline, promoted nationalist messaging, and expanded China's international initiatives such as the Belt and Road Initiative.
