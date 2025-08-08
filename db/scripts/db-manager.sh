#!/bin/bash
# Database Management Scripts for PCC LMS
# Version: 2025-08-08

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_DB=${POSTGRES_DB:-pcc_lms}
POSTGRES_USER=${POSTGRES_USER:-pcc_user}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-pcc_password}
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

MONGODB_DB=${MONGODB_DB:-pcc_lms_notifications}
MONGODB_HOST=${MONGODB_HOST:-localhost}
MONGODB_PORT=${MONGODB_PORT:-27017}

CLICKHOUSE_DB=${CLICKHOUSE_DB:-pcc_lms_analytics}
CLICKHOUSE_HOST=${CLICKHOUSE_HOST:-localhost}
CLICKHOUSE_PORT=${CLICKHOUSE_PORT:-8123}

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_postgres_connection() {
    log_info "Checking PostgreSQL connection..."
    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "PostgreSQL connection successful"
        return 0
    else
        log_error "PostgreSQL connection failed"
        return 1
    fi
}

check_mongodb_connection() {
    log_info "Checking MongoDB connection..."
    if mongosh --host $MONGODB_HOST:$MONGODB_PORT --eval "db.runCommand('ismaster')" >/dev/null 2>&1; then
        log_success "MongoDB connection successful"
        return 0
    else
        log_error "MongoDB connection failed"
        return 1
    fi
}

check_clickhouse_connection() {
    log_info "Checking ClickHouse connection..."
    if curl -s "http://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/" >/dev/null 2>&1; then
        log_success "ClickHouse connection successful"
        return 0
    else
        log_error "ClickHouse connection failed"
        return 1
    fi
}

create_databases() {
    log_info "Creating databases..."
    
    # PostgreSQL
    if check_postgres_connection; then
        log_info "Creating PostgreSQL database: $POSTGRES_DB"
        PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "CREATE DATABASE $POSTGRES_DB;" 2>/dev/null || log_warning "PostgreSQL database might already exist"
    fi
    
    # MongoDB (database is created automatically when first collection is created)
    if check_mongodb_connection; then
        log_info "MongoDB database will be created automatically when first used"
    fi
    
    # ClickHouse
    if check_clickhouse_connection; then
        log_info "Creating ClickHouse database: $CLICKHOUSE_DB"
        curl -s "http://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/" -d "CREATE DATABASE IF NOT EXISTS $CLICKHOUSE_DB" >/dev/null
    fi
    
    log_success "Database creation completed"
}

run_postgres_migrations() {
    log_info "Running PostgreSQL migrations..."
    
    if ! check_postgres_connection; then
        log_error "Cannot connect to PostgreSQL"
        return 1
    fi
    
    # Run migrations in order
    for migration_file in db/migrations/postgresql/*.sql; do
        if [[ -f "$migration_file" ]]; then
            log_info "Running migration: $(basename $migration_file)"
            PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -f "$migration_file"
            if [[ $? -eq 0 ]]; then
                log_success "Migration completed: $(basename $migration_file)"
            else
                log_error "Migration failed: $(basename $migration_file)"
                return 1
            fi
        fi
    done
    
    log_success "All PostgreSQL migrations completed"
}

run_postgres_seeds() {
    log_info "Running PostgreSQL seeds..."
    
    if ! check_postgres_connection; then
        log_error "Cannot connect to PostgreSQL"
        return 1
    fi
    
    # Run seeds in order
    for seed_file in db/seeds/*.sql; do
        if [[ -f "$seed_file" ]]; then
            log_info "Running seed: $(basename $seed_file)"
            PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -f "$seed_file"
            if [[ $? -eq 0 ]]; then
                log_success "Seed completed: $(basename $seed_file)"
            else
                log_warning "Seed might have failed or already exists: $(basename $seed_file)"
            fi
        fi
    done
    
    log_success "All PostgreSQL seeds completed"
}

run_mongodb_migrations() {
    log_info "Running MongoDB migrations..."
    
    if ! check_mongodb_connection; then
        log_error "Cannot connect to MongoDB"
        return 1
    fi
    
    # Run MongoDB migrations
    for migration_file in db/migrations/mongodb/*.js; do
        if [[ -f "$migration_file" ]]; then
            log_info "Running migration: $(basename $migration_file)"
            mongosh --host $MONGODB_HOST:$MONGODB_PORT $MONGODB_DB "$migration_file"
            if [[ $? -eq 0 ]]; then
                log_success "Migration completed: $(basename $migration_file)"
            else
                log_error "Migration failed: $(basename $migration_file)"
                return 1
            fi
        fi
    done
    
    log_success "All MongoDB migrations completed"
}

run_clickhouse_migrations() {
    log_info "Running ClickHouse migrations..."
    
    if ! check_clickhouse_connection; then
        log_error "Cannot connect to ClickHouse"
        return 1
    fi
    
    # Run ClickHouse migrations
    for migration_file in db/migrations/clickhouse/*.sql; do
        if [[ -f "$migration_file" ]]; then
            log_info "Running migration: $(basename $migration_file)"
            clickhouse-client --host $CLICKHOUSE_HOST --port 9000 --database $CLICKHOUSE_DB --multiquery < "$migration_file"
            if [[ $? -eq 0 ]]; then
                log_success "Migration completed: $(basename $migration_file)"
            else
                log_error "Migration failed: $(basename $migration_file)"
                return 1
            fi
        fi
    done
    
    log_success "All ClickHouse migrations completed"
}

backup_postgres() {
    local backup_dir="db/backups/postgresql"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/backup_$timestamp.sql"
    
    log_info "Creating PostgreSQL backup..."
    mkdir -p "$backup_dir"
    
    PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB > "$backup_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "PostgreSQL backup created: $backup_file"
        
        # Compress the backup
        gzip "$backup_file"
        log_success "Backup compressed: ${backup_file}.gz"
    else
        log_error "PostgreSQL backup failed"
        return 1
    fi
}

backup_mongodb() {
    local backup_dir="db/backups/mongodb"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$backup_dir/backup_$timestamp"
    
    log_info "Creating MongoDB backup..."
    mkdir -p "$backup_path"
    
    mongodump --host $MONGODB_HOST:$MONGODB_PORT --db $MONGODB_DB --out "$backup_path"
    
    if [[ $? -eq 0 ]]; then
        log_success "MongoDB backup created: $backup_path"
        
        # Compress the backup
        tar -czf "${backup_path}.tar.gz" -C "$backup_dir" "backup_$timestamp"
        rm -rf "$backup_path"
        log_success "Backup compressed: ${backup_path}.tar.gz"
    else
        log_error "MongoDB backup failed"
        return 1
    fi
}

restore_postgres() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "Please provide backup file path"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_warning "This will overwrite the existing database. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    log_info "Restoring PostgreSQL from: $backup_file"
    
    # Drop and recreate database
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "CREATE DATABASE $POSTGRES_DB;"
    
    # Restore from backup
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB
    else
        PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB < "$backup_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "PostgreSQL restore completed"
    else
        log_error "PostgreSQL restore failed"
        return 1
    fi
}

show_status() {
    log_info "Database Status Check"
    echo "========================"
    
    echo -n "PostgreSQL: "
    if check_postgres_connection >/dev/null 2>&1; then
        echo -e "${GREEN}Connected${NC}"
    else
        echo -e "${RED}Disconnected${NC}"
    fi
    
    echo -n "MongoDB: "
    if check_mongodb_connection >/dev/null 2>&1; then
        echo -e "${GREEN}Connected${NC}"
    else
        echo -e "${RED}Disconnected${NC}"
    fi
    
    echo -n "ClickHouse: "
    if check_clickhouse_connection >/dev/null 2>&1; then
        echo -e "${GREEN}Connected${NC}"
    else
        echo -e "${RED}Disconnected${NC}"
    fi
    
    echo "========================"
}

show_help() {
    echo "PCC LMS Database Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init          Initialize all databases and run migrations"
    echo "  migrate       Run all pending migrations"
    echo "  seed          Run database seeds"
    echo "  backup        Create backups of all databases"
    echo "  restore       Restore from backup (interactive)"
    echo "  status        Show database connection status"
    echo "  reset         Drop and recreate all databases (DANGEROUS)"
    echo "  help          Show this help message"
    echo ""
    echo "Database-specific commands:"
    echo "  pg:migrate    Run PostgreSQL migrations only"
    echo "  pg:seed       Run PostgreSQL seeds only"
    echo "  pg:backup     Backup PostgreSQL only"
    echo "  mongo:migrate Run MongoDB migrations only"
    echo "  clickhouse:migrate Run ClickHouse migrations only"
    echo ""
    echo "Environment Variables:"
    echo "  POSTGRES_HOST     PostgreSQL host (default: localhost)"
    echo "  POSTGRES_PORT     PostgreSQL port (default: 5432)"
    echo "  POSTGRES_DB       PostgreSQL database name (default: pcc_lms)"
    echo "  POSTGRES_USER     PostgreSQL username (default: pcc_user)"
    echo "  POSTGRES_PASSWORD PostgreSQL password (default: pcc_password)"
    echo "  MONGODB_HOST      MongoDB host (default: localhost)"
    echo "  MONGODB_PORT      MongoDB port (default: 27017)"
    echo "  MONGODB_DB        MongoDB database name (default: pcc_lms_notifications)"
    echo "  CLICKHOUSE_HOST   ClickHouse host (default: localhost)"
    echo "  CLICKHOUSE_PORT   ClickHouse port (default: 8123)"
    echo "  CLICKHOUSE_DB     ClickHouse database name (default: pcc_lms_analytics)"
}

# Main script logic
case "$1" in
    "init")
        log_info "Initializing PCC LMS databases..."
        create_databases
        run_postgres_migrations
        run_postgres_seeds
        run_mongodb_migrations
        run_clickhouse_migrations
        log_success "Database initialization completed!"
        ;;
    "migrate")
        log_info "Running all migrations..."
        run_postgres_migrations
        run_mongodb_migrations
        run_clickhouse_migrations
        log_success "All migrations completed!"
        ;;
    "seed")
        run_postgres_seeds
        ;;
    "backup")
        log_info "Creating backups..."
        backup_postgres
        backup_mongodb
        log_success "All backups completed!"
        ;;
    "status")
        show_status
        ;;
    "pg:migrate")
        run_postgres_migrations
        ;;
    "pg:seed")
        run_postgres_seeds
        ;;
    "pg:backup")
        backup_postgres
        ;;
    "mongo:migrate")
        run_mongodb_migrations
        ;;
    "clickhouse:migrate")
        run_clickhouse_migrations
        ;;
    "reset")
        log_warning "This will DROP all databases and recreate them. This is IRREVERSIBLE!"
        log_warning "Type 'RESET' to continue:"
        read -r confirmation
        if [[ "$confirmation" == "RESET" ]]; then
            log_info "Resetting databases..."
            # Drop databases
            PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "DROP DATABASE IF EXISTS $POSTGRES_DB;" 2>/dev/null
            mongosh --host $MONGODB_HOST:$MONGODB_PORT --eval "db.dropDatabase()" $MONGODB_DB 2>/dev/null
            curl -s "http://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/" -d "DROP DATABASE IF EXISTS $CLICKHOUSE_DB" >/dev/null 2>&1
            
            # Recreate and migrate
            create_databases
            run_postgres_migrations
            run_postgres_seeds
            run_mongodb_migrations
            run_clickhouse_migrations
            log_success "Database reset completed!"
        else
            log_info "Reset cancelled"
        fi
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
