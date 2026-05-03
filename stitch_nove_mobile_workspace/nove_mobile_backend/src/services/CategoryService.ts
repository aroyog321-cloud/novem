import { executeQuery, executeUpdate } from '../database';
import { Category } from '../types';

interface CategoryRow {
  id: string;
  name: string;
  color: string;
  sort_order: number;
}

const mapRowToCategory = (row: CategoryRow): Category => ({
  id: row.id,
  name: row.name,
  color: row.color,
  order: row.sort_order,
});

export class CategoryService {
  static getAllCategories(): Category[] {
    const rows = executeQuery<CategoryRow>('SELECT * FROM categories ORDER BY sort_order ASC');
    return rows.map(mapRowToCategory);
  }

  static getCategoryById(id: string): Category | null {
    const rows = executeQuery<CategoryRow>('SELECT * FROM categories WHERE id = ?', [id]);
    return rows.length > 0 ? mapRowToCategory(rows[0]) : null;
  }

  static getCategoryByName(name: string): Category | null {
    const rows = executeQuery<CategoryRow>('SELECT * FROM categories WHERE name = ?', [name]);
    return rows.length > 0 ? mapRowToCategory(rows[0]) : null;
  }

  static createCategory(name: string, color: string): Category {
    const id = `cat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const maxOrder = executeQuery<{ max_order: number }>('SELECT MAX(sort_order) as max_order FROM categories');
    const order = (maxOrder[0]?.max_order ?? -1) + 1;

    executeUpdate(
      'INSERT INTO categories (id, name, color, sort_order) VALUES (?, ?, ?, ?)',
      [id, name, color, order]
    );

    return { id, name, color, order };
  }

  static updateCategory(id: string, updates: Partial<Pick<Category, 'name' | 'color' | 'order'>>): Category | null {
    const existing = this.getCategoryById(id);
    if (!existing) return null;

    const name = updates.name ?? existing.name;
    const color = updates.color ?? existing.color;
    const order = updates.order ?? existing.order;

    executeUpdate(
      'UPDATE categories SET name = ?, color = ?, sort_order = ? WHERE id = ?',
      [name, color, order, id]
    );

    return this.getCategoryById(id);
  }

  static deleteCategory(id: string): boolean {
    const affected = executeUpdate('DELETE FROM categories WHERE id = ?', [id]);
    return affected > 0;
  }

  static reorderCategories(categoryIds: string[]): void {
    categoryIds.forEach((id, index) => {
      executeUpdate('UPDATE categories SET sort_order = ? WHERE id = ?', [index, id]);
    });
  }
}
