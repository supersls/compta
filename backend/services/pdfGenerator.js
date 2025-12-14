const PDFDocument = require('pdfkit');

/**
 * Service de génération de PDF réutilisable pour tous les documents comptables
 */
class PDFGenerator {
  constructor() {
    this.pageMargin = 50;
    this.colors = {
      primary: '#2563eb',
      secondary: '#64748b',
      success: '#22c55e',
      danger: '#ef4444',
      warning: '#f59e0b',
      lightGray: '#f1f5f9',
      darkGray: '#334155',
    };
  }

  /**
   * Crée un nouveau document PDF
   */
  createDocument() {
    return new PDFDocument({
      size: 'A4',
      margin: this.pageMargin,
      info: {
        Title: 'Document Comptable',
        Author: 'Compta EI',
        Subject: 'Document comptable généré automatiquement',
      },
    });
  }

  /**
   * Ajoute l'en-tête du document
   */
  addHeader(doc, title, subtitle = null) {
    doc
      .fontSize(20)
      .font('Helvetica-Bold')
      .text(title, { align: 'center' })
      .moveDown(0.5);

    if (subtitle) {
      doc
        .fontSize(12)
        .font('Helvetica')
        .fillColor(this.colors.secondary)
        .text(subtitle, { align: 'center' })
        .moveDown(0.5);
    }

    // Ligne de séparation
    doc
      .strokeColor(this.colors.primary)
      .lineWidth(2)
      .moveTo(this.pageMargin, doc.y)
      .lineTo(doc.page.width - this.pageMargin, doc.y)
      .stroke()
      .moveDown(1);

    doc.fillColor('#000000'); // Reset color
  }

  /**
   * Ajoute un pied de page
   */
  addFooter(doc) {
    const pageHeight = doc.page.height;
    const pageWidth = doc.page.width;
    
    doc
      .fontSize(8)
      .fillColor(this.colors.secondary)
      .text(
        `Document généré le ${this.formatDate(new Date())}`,
        this.pageMargin,
        pageHeight - 30,
        { align: 'center', width: pageWidth - 2 * this.pageMargin }
      );
  }

  /**
   * Crée un tableau simple
   */
  addTable(doc, headers, rows, options = {}) {
    const {
      startY = doc.y,
      columnWidths = null,
      headerColor = this.colors.primary,
      headerTextColor = '#ffffff',
      alternateRowColor = this.colors.lightGray,
    } = options;

    const tableWidth = doc.page.width - 2 * this.pageMargin;
    const colCount = headers.length;
    const colWidths = columnWidths || Array(colCount).fill(tableWidth / colCount);

    let currentY = startY;

    // En-tête du tableau
    doc
      .fillColor(headerColor)
      .rect(this.pageMargin, currentY, tableWidth, 25)
      .fill();

    let currentX = this.pageMargin;
    doc.fillColor(headerTextColor).font('Helvetica-Bold').fontSize(10);

    headers.forEach((header, i) => {
      doc.text(
        header,
        currentX + 5,
        currentY + 7,
        { width: colWidths[i] - 10, align: 'left' }
      );
      currentX += colWidths[i];
    });

    currentY += 25;

    // Lignes du tableau
    doc.fillColor('#000000').font('Helvetica').fontSize(9);

    rows.forEach((row, rowIndex) => {
      // Alternance de couleur
      if (rowIndex % 2 === 1) {
        doc
          .fillColor(alternateRowColor)
          .rect(this.pageMargin, currentY, tableWidth, 20)
          .fill();
        doc.fillColor('#000000');
      }

      currentX = this.pageMargin;
      row.forEach((cell, colIndex) => {
        const align = typeof cell === 'number' || this.isCurrency(cell) ? 'right' : 'left';
        doc.text(
          String(cell),
          currentX + 5,
          currentY + 5,
          { width: colWidths[colIndex] - 10, align }
        );
        currentX += colWidths[colIndex];
      });

      currentY += 20;

      // Nouvelle page si nécessaire
      if (currentY > doc.page.height - 100) {
        doc.addPage();
        currentY = this.pageMargin;
      }
    });

    doc.y = currentY + 10;
  }

  /**
   * Ajoute une section avec titre
   */
  addSection(doc, title, color = this.colors.primary) {
    doc
      .moveDown(0.5)
      .fontSize(14)
      .font('Helvetica-Bold')
      .fillColor(color)
      .text(title)
      .moveDown(0.3)
      .fillColor('#000000')
      .font('Helvetica');
  }

  /**
   * Ajoute une ligne clé-valeur
   */
  addKeyValue(doc, key, value, options = {}) {
    const {
      keyWidth = 200,
      bold = false,
      fontSize = 10,
      color = '#000000',
    } = options;

    const y = doc.y;
    
    doc
      .fontSize(fontSize)
      .fillColor(this.colors.darkGray)
      .text(key, this.pageMargin, y, { width: keyWidth, continued: false });

    doc
      .fillColor(color)
      .font(bold ? 'Helvetica-Bold' : 'Helvetica')
      .text(
        String(value),
        this.pageMargin + keyWidth,
        y,
        { align: 'right', width: doc.page.width - 2 * this.pageMargin - keyWidth }
      )
      .moveDown(0.3);

    doc.fillColor('#000000').font('Helvetica');
  }

  /**
   * Ajoute un encadré mis en évidence
   */
  addHighlightBox(doc, text, value, options = {}) {
    const {
      backgroundColor = this.colors.lightGray,
      borderColor = this.colors.primary,
      textColor = '#000000',
      valueColor = this.colors.primary,
    } = options;

    const boxHeight = 60;
    const boxWidth = doc.page.width - 2 * this.pageMargin;
    const currentY = doc.y;

    // Fond
    doc
      .fillColor(backgroundColor)
      .rect(this.pageMargin, currentY, boxWidth, boxHeight)
      .fill();

    // Bordure
    doc
      .strokeColor(borderColor)
      .lineWidth(2)
      .rect(this.pageMargin, currentY, boxWidth, boxHeight)
      .stroke();

    // Texte
    doc
      .fillColor(textColor)
      .fontSize(12)
      .font('Helvetica-Bold')
      .text(text, this.pageMargin + 20, currentY + 15, {
        width: boxWidth - 40,
        align: 'center',
      });

    // Valeur
    doc
      .fillColor(valueColor)
      .fontSize(18)
      .text(value, this.pageMargin + 20, currentY + 32, {
        width: boxWidth - 40,
        align: 'center',
      });

    doc.y = currentY + boxHeight + 20;
    doc.fillColor('#000000').font('Helvetica');
  }

  /**
   * Formate une date
   */
  formatDate(date) {
    if (!date) return '';
    const d = new Date(date);
    return d.toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  }

  /**
   * Formate un montant
   */
  formatCurrency(amount) {
    if (amount == null) return '0,00 €';
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR',
    }).format(amount);
  }

  /**
   * Vérifie si une chaîne est une devise
   */
  isCurrency(str) {
    return typeof str === 'string' && str.includes('€');
  }

  /**
   * Génère le PDF du compte de résultat
   */
  generateCompteResultat(data) {
    const doc = this.createDocument();
    const { periode_debut, periode_fin, charges, produits, total_charges, total_produits, resultat_net } = data;

    // En-tête
    this.addHeader(
      doc,
      'COMPTE DE RÉSULTAT',
      `Période du ${this.formatDate(periode_debut)} au ${this.formatDate(periode_fin)}`
    );

    const startY = doc.y;
    const pageWidth = doc.page.width - 2 * this.pageMargin;
    const columnWidth = (pageWidth - 20) / 2;

    // CHARGES (colonne gauche)
    const chargesX = this.pageMargin;
    doc.y = startY;

    doc
      .fillColor(this.colors.danger)
      .rect(chargesX, doc.y, columnWidth, 30)
      .fill();

    doc
      .fillColor('#ffffff')
      .fontSize(12)
      .font('Helvetica-Bold')
      .text('CHARGES', chargesX, doc.y + 10, {
        width: columnWidth,
        align: 'center',
      });

    doc.y += 35;
    doc.fillColor('#000000').font('Helvetica').fontSize(9);

    const chargesEntries = Object.entries(charges);
    chargesEntries.forEach(([category, amount]) => {
      const y = doc.y;
      doc.text(category, chargesX + 5, y, { width: columnWidth - 100 });
      doc.text(this.formatCurrency(amount), chargesX + columnWidth - 95, y, {
        width: 90,
        align: 'right',
      });
      doc.moveDown(0.5);
    });

    // Ligne de total charges
    const chargesBottomY = doc.y + 10;
    doc
      .strokeColor(this.colors.danger)
      .lineWidth(1.5)
      .moveTo(chargesX, chargesBottomY)
      .lineTo(chargesX + columnWidth, chargesBottomY)
      .stroke();

    doc.y = chargesBottomY + 5;
    doc
      .fontSize(11)
      .font('Helvetica-Bold')
      .fillColor(this.colors.danger)
      .text('TOTAL CHARGES', chargesX + 5, doc.y, { width: columnWidth - 100 });
    doc.text(this.formatCurrency(total_charges), chargesX + columnWidth - 95, doc.y, {
      width: 90,
      align: 'right',
    });

    // PRODUITS (colonne droite)
    const produitsX = this.pageMargin + columnWidth + 20;
    doc.y = startY;

    doc
      .fillColor(this.colors.success)
      .rect(produitsX, doc.y, columnWidth, 30)
      .fill();

    doc
      .fillColor('#ffffff')
      .fontSize(12)
      .font('Helvetica-Bold')
      .text('PRODUITS', produitsX, doc.y + 10, {
        width: columnWidth,
        align: 'center',
      });

    doc.y += 35;
    doc.fillColor('#000000').font('Helvetica').fontSize(9);

    const produitsEntries = Object.entries(produits);
    produitsEntries.forEach(([category, amount]) => {
      const y = doc.y;
      doc.text(category, produitsX + 5, y, { width: columnWidth - 100 });
      doc.text(this.formatCurrency(amount), produitsX + columnWidth - 95, y, {
        width: 90,
        align: 'right',
      });
      doc.moveDown(0.5);
    });

    // Ligne de total produits
    const produitsBottomY = doc.y + 10;
    doc
      .strokeColor(this.colors.success)
      .lineWidth(1.5)
      .moveTo(produitsX, produitsBottomY)
      .lineTo(produitsX + columnWidth, produitsBottomY)
      .stroke();

    doc.y = produitsBottomY + 5;
    doc
      .fontSize(11)
      .font('Helvetica-Bold')
      .fillColor(this.colors.success)
      .text('TOTAL PRODUITS', produitsX + 5, doc.y, { width: columnWidth - 100 });
    doc.text(this.formatCurrency(total_produits), produitsX + columnWidth - 95, doc.y, {
      width: 90,
      align: 'right',
    });

    // Résultat net
    doc.y = Math.max(chargesBottomY, produitsBottomY) + 60;

    const isBenefit = resultat_net >= 0;
    this.addHighlightBox(
      doc,
      isBenefit ? 'BÉNÉFICE NET' : 'PERTE NETTE',
      this.formatCurrency(Math.abs(resultat_net)),
      {
        backgroundColor: isBenefit ? '#dcfce7' : '#fee2e2',
        borderColor: isBenefit ? this.colors.success : this.colors.danger,
        valueColor: isBenefit ? this.colors.success : this.colors.danger,
      }
    );

    // Pied de page
    this.addFooter(doc);

    return doc;
  }

  /**
   * Génère le PDF du journal comptable
   */
  generateJournal(ecritures, options = {}) {
    const doc = this.createDocument();
    const { debut, fin } = options;

    this.addHeader(
      doc,
      'JOURNAL COMPTABLE',
      debut && fin ? `Période du ${this.formatDate(debut)} au ${this.formatDate(fin)}` : null
    );

    const headers = ['Date', 'Compte', 'Libellé', 'Débit', 'Crédit'];
    const rows = ecritures.map(e => [
      this.formatDate(e.date_ecriture),
      e.compte || '',
      e.libelle || '',
      e.debit ? this.formatCurrency(e.debit) : '',
      e.credit ? this.formatCurrency(e.credit) : '',
    ]);

    this.addTable(doc, headers, rows, {
      columnWidths: [80, 80, 200, 100, 100],
    });

    this.addFooter(doc);
    return doc;
  }

  /**
   * Génère le PDF du grand livre
   */
  generateGrandLivre(comptes, options = {}) {
    const doc = this.createDocument();
    const { debut, fin } = options;

    this.addHeader(
      doc,
      'GRAND LIVRE',
      debut && fin ? `Période du ${this.formatDate(debut)} au ${this.formatDate(fin)}` : null
    );

    comptes.forEach((compte, index) => {
      if (index > 0) doc.moveDown(1);

      this.addSection(doc, `Compte ${compte.numero_compte} - ${compte.nom_compte || ''}`);

      const ecritures = Array.isArray(compte.ecritures) ? compte.ecritures : [];
      const headers = ['Date', 'Libellé', 'Débit', 'Crédit'];
      const rows = ecritures.map(e => [
        this.formatDate(e.date_ecriture),
        e.libelle || '',
        e.debit ? this.formatCurrency(e.debit) : '',
        e.credit ? this.formatCurrency(e.credit) : '',
      ]);

      this.addTable(doc, headers, rows, {
        columnWidths: [80, 250, 100, 100],
      });

      this.addKeyValue(doc, 'Solde du compte', this.formatCurrency(compte.solde_final), {
        bold: true,
        fontSize: 11,
        color: compte.solde_final >= 0 ? this.colors.success : this.colors.danger,
      });

      if (index < comptes.length - 1 && doc.y > doc.page.height - 200) {
        doc.addPage();
      }
    });

    this.addFooter(doc);
    return doc;
  }

  /**
   * Génère le PDF du bilan comptable
   */
  generateBilan(data) {
    const doc = this.createDocument();
    const { date_arrete, actif, passif, total_actif, total_passif } = data;

    this.addHeader(doc, 'BILAN COMPTABLE', `Arrêté au ${this.formatDate(date_arrete)}`);

    const startY = doc.y;
    const pageWidth = doc.page.width - 2 * this.pageMargin;
    const columnWidth = (pageWidth - 20) / 2;

    // ACTIF (colonne gauche)
    const actifX = this.pageMargin;
    doc.y = startY;

    doc
      .fillColor(this.colors.primary)
      .rect(actifX, doc.y, columnWidth, 30)
      .fill();

    doc
      .fillColor('#ffffff')
      .fontSize(12)
      .font('Helvetica-Bold')
      .text('ACTIF', actifX, doc.y + 10, { width: columnWidth, align: 'center' });

    doc.y += 35;
    doc.fillColor('#000000').font('Helvetica').fontSize(9);

    Object.entries(actif).forEach(([category, amount]) => {
      const y = doc.y;
      doc.text(category, actifX + 5, y, { width: columnWidth - 100 });
      doc.text(this.formatCurrency(amount), actifX + columnWidth - 95, y, {
        width: 90,
        align: 'right',
      });
      doc.moveDown(0.5);
    });

    const actifBottomY = doc.y + 10;
    doc
      .strokeColor(this.colors.primary)
      .lineWidth(1.5)
      .moveTo(actifX, actifBottomY)
      .lineTo(actifX + columnWidth, actifBottomY)
      .stroke();

    doc.y = actifBottomY + 5;
    doc
      .fontSize(11)
      .font('Helvetica-Bold')
      .text('TOTAL ACTIF', actifX + 5, doc.y, { width: columnWidth - 100 });
    doc.text(this.formatCurrency(total_actif), actifX + columnWidth - 95, doc.y, {
      width: 90,
      align: 'right',
    });

    // PASSIF (colonne droite)
    const passifX = this.pageMargin + columnWidth + 20;
    doc.y = startY;

    doc
      .fillColor(this.colors.warning)
      .rect(passifX, doc.y, columnWidth, 30)
      .fill();

    doc
      .fillColor('#ffffff')
      .fontSize(12)
      .font('Helvetica-Bold')
      .text('PASSIF', passifX, doc.y + 10, { width: columnWidth, align: 'center' });

    doc.y += 35;
    doc.fillColor('#000000').font('Helvetica').fontSize(9);

    Object.entries(passif).forEach(([category, amount]) => {
      const y = doc.y;
      doc.text(category, passifX + 5, y, { width: columnWidth - 100 });
      doc.text(this.formatCurrency(amount), passifX + columnWidth - 95, y, {
        width: 90,
        align: 'right',
      });
      doc.moveDown(0.5);
    });

    const passifBottomY = doc.y + 10;
    doc
      .strokeColor(this.colors.warning)
      .lineWidth(1.5)
      .moveTo(passifX, passifBottomY)
      .lineTo(passifX + columnWidth, passifBottomY)
      .stroke();

    doc.y = passifBottomY + 5;
    doc
      .fontSize(11)
      .font('Helvetica-Bold')
      .text('TOTAL PASSIF', passifX + 5, doc.y, { width: columnWidth - 100 });
    doc.text(this.formatCurrency(total_passif), passifX + columnWidth - 95, doc.y, {
      width: 90,
      align: 'right',
    });

    this.addFooter(doc);
    return doc;
  }
}

module.exports = new PDFGenerator();
