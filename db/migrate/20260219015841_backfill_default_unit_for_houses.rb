class BackfillDefaultUnitForHouses < ActiveRecord::Migration[7.2]
  def up
    # Find all house properties (property_type = 0) with no units and create a default unit
    execute <<~SQL
      INSERT INTO units (property_id, identifier, created_at, updated_at)
      SELECT p.id, 'Main Unit', NOW(), NOW()
      FROM properties p
      WHERE p.property_type = 0
        AND NOT EXISTS (SELECT 1 FROM units u WHERE u.property_id = p.id)
    SQL
  end

  def down
    # Remove auto-created "Main Unit" units from houses that only have that one unit
    execute <<~SQL
      DELETE FROM units
      WHERE identifier = 'Main Unit'
        AND property_id IN (
          SELECT p.id FROM properties p WHERE p.property_type = 0
        )
        AND (SELECT COUNT(*) FROM units u2 WHERE u2.property_id = units.property_id) = 1
    SQL
  end
end
